// Closed-loop, multi-threaded load tester for dyar.app.
//
// It runs a sequence of "stages" at increasing concurrency. For each stage it
// reports sustainable throughput (req/s) and latency percentiles, then finds
// the peak sustainable throughput across stages. That peak is converted to an
// estimate of "users per hour" using a configurable per-user request model.
//
// Usage:
//   node src/loadtest.js \
//     --target https://dyar.app/ \
//     --stages 1,5,10,25,50,100,200,400,800 \
//     --duration 8 \           # seconds per stage
//     --cooldown 2 \           # seconds between stages
//     --reqs-per-user 8 \      # requests an average user session makes
//     --error-abort 0.10       # stop ramp if error rate exceeds this
//
import { Worker } from 'node:worker_threads';
import { performance } from 'node:perf_hooks';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const val = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : 'true';
      args[key] = val;
    }
  }
  return args;
}

const args = parseArgs(process.argv);
const TARGET = args.target || 'https://dyar.app/';
const STAGES = (args.stages || '1,5,10,25,50,100,200,400,800')
  .split(',')
  .map((s) => parseInt(s.trim(), 10))
  .filter((n) => n > 0);
const DURATION_MS = (parseFloat(args.duration) || 8) * 1000;
const COOLDOWN_MS = (parseFloat(args.cooldown) || 2) * 1000;
const REQS_PER_USER = parseFloat(args['reqs-per-user']) || 8;
const ERROR_ABORT = parseFloat(args['error-abort']) || 0.1;
const THREADS = Math.max(1, Math.min(os.cpus().length, parseInt(args.threads, 10) || os.cpus().length));
const OUT = args.out || path.join(__dirname, '..', 'results', `run-${Date.now()}.json`);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function percentile(sortedArr, p) {
  if (sortedArr.length === 0) return 0;
  const idx = Math.min(sortedArr.length - 1, Math.floor((p / 100) * sortedArr.length));
  return sortedArr[idx];
}

function runWorker(concurrency, durationMs) {
  return new Promise((resolve, reject) => {
    const worker = new Worker(path.join(__dirname, 'worker.js'), {
      workerData: { target: TARGET, concurrency, durationMs, method: 'GET', headers: {} },
    });
    worker.once('message', (msg) => {
      worker.terminate();
      resolve(msg);
    });
    worker.once('error', reject);
  });
}

// Split a stage's total concurrency across worker threads as evenly as possible.
function splitConcurrency(totalConcurrency, threads) {
  const t = Math.min(threads, totalConcurrency);
  const base = Math.floor(totalConcurrency / t);
  const rem = totalConcurrency % t;
  const parts = [];
  for (let i = 0; i < t; i++) parts.push(base + (i < rem ? 1 : 0));
  return parts;
}

async function runStage(concurrency) {
  const parts = splitConcurrency(concurrency, THREADS);
  const start = performance.now();
  const results = await Promise.all(parts.map((c) => runWorker(c, DURATION_MS)));
  const wallSec = (performance.now() - start) / 1000;

  let total = 0;
  let networkErrors = 0;
  let bytes = 0;
  const status = new Map();
  let allLat = [];
  for (const r of results) {
    total += r.total;
    networkErrors += r.networkErrors;
    bytes += r.bytes;
    for (const [code, n] of r.status) status.set(code, (status.get(code) || 0) + n);
    allLat = allLat.concat(Array.from(r.latencies));
  }
  allLat.sort((a, b) => a - b);

  const http2xx = Array.from(status.entries())
    .filter(([c]) => c >= 200 && c < 400)
    .reduce((s, [, n]) => s + n, 0);
  const httpErrors = total - http2xx; // 4xx/5xx + network errors
  const errorRate = total > 0 ? httpErrors / total : 0;
  const rps = total / wallSec;

  return {
    concurrency,
    threads: parts.length,
    wallSec: +wallSec.toFixed(2),
    total,
    rps: +rps.toFixed(1),
    successRps: +((http2xx / wallSec)).toFixed(1),
    bytesMB: +(bytes / 1024 / 1024).toFixed(1),
    throughputMbps: +((bytes * 8) / 1e6 / wallSec).toFixed(1),
    networkErrors,
    errorRate: +(errorRate * 100).toFixed(2),
    status: Object.fromEntries(Array.from(status.entries()).sort((a, b) => a[0] - b[0])),
    latencyMs: {
      min: +percentile(allLat, 0).toFixed(1),
      p50: +percentile(allLat, 50).toFixed(1),
      p90: +percentile(allLat, 90).toFixed(1),
      p95: +percentile(allLat, 95).toFixed(1),
      p99: +percentile(allLat, 99).toFixed(1),
      max: +(allLat[allLat.length - 1] || 0).toFixed(1),
    },
  };
}

function fmtRow(s) {
  return [
    String(s.concurrency).padStart(5),
    String(s.rps).padStart(10),
    String(s.successRps).padStart(11),
    String(s.errorRate + '%').padStart(8),
    String(s.latencyMs.p50).padStart(8),
    String(s.latencyMs.p95).padStart(9),
    String(s.latencyMs.p99).padStart(9),
    String(s.latencyMs.max).padStart(9),
    String(s.throughputMbps).padStart(9),
  ].join(' ');
}

async function main() {
  console.log('='.repeat(96));
  console.log('dyar.app — Load / Capacity Test (closed-loop, think-time = 0)');
  console.log('='.repeat(96));
  console.log(`Target           : ${TARGET}`);
  console.log(`Generator        : ${os.hostname()} — ${os.cpus().length} vCPU, using ${THREADS} worker threads`);
  console.log(`Stages (conc.)   : ${STAGES.join(', ')}`);
  console.log(`Duration/stage   : ${DURATION_MS / 1000}s   Cooldown: ${COOLDOWN_MS / 1000}s`);
  console.log(`Abort if error%  : > ${(ERROR_ABORT * 100).toFixed(0)}%`);
  console.log('='.repeat(96));
  console.log(
    ['conc', 'req/s', 'ok req/s', 'err%', 'p50 ms', 'p95 ms', 'p99 ms', 'max ms', 'Mbps']
      .map((h, i) => h.padStart([5, 10, 11, 8, 8, 9, 9, 9, 9][i]))
      .join(' ')
  );
  console.log('-'.repeat(96));

  const stages = [];
  let peak = null;
  for (const c of STAGES) {
    const s = await runStage(c);
    stages.push(s);
    console.log(fmtRow(s));
    if (!peak || s.successRps > peak.successRps) peak = s;
    if (s.errorRate / 100 > ERROR_ABORT) {
      console.log('-'.repeat(96));
      console.log(`Aborting ramp: error rate ${s.errorRate}% exceeded ${(ERROR_ABORT * 100).toFixed(0)}% at concurrency ${c}.`);
      break;
    }
    await sleep(COOLDOWN_MS);
  }

  console.log('-'.repeat(96));
  const peakRps = peak.successRps;
  const usersPerHour = Math.round((peakRps * 3600) / REQS_PER_USER);
  console.log('PEAK SUSTAINABLE (successful) THROUGHPUT');
  console.log(`  concurrency      : ${peak.concurrency}`);
  console.log(`  successful req/s : ${peakRps}`);
  console.log(`  p95 latency      : ${peak.latencyMs.p95} ms   p99: ${peak.latencyMs.p99} ms`);
  console.log(`  error rate       : ${peak.errorRate}%`);
  console.log('');
  console.log('CAPACITY MODEL  (users/hour = peak_ok_req_per_s * 3600 / requests_per_user_session)');
  console.log(`  requests/user    : ${REQS_PER_USER}`);
  console.log(`  => USERS / HOUR  : ~${usersPerHour.toLocaleString()}`);
  console.log('='.repeat(96));

  const report = {
    target: TARGET,
    startedAt: new Date().toISOString(),
    generator: { host: os.hostname(), vcpu: os.cpus().length, threads: THREADS },
    config: { stages: STAGES, durationSec: DURATION_MS / 1000, cooldownSec: COOLDOWN_MS / 1000, reqsPerUser: REQS_PER_USER },
    stages,
    peak: { concurrency: peak.concurrency, successRps: peakRps, p95Ms: peak.latencyMs.p95, p99Ms: peak.latencyMs.p99, errorRate: peak.errorRate },
    capacity: { reqsPerUser: REQS_PER_USER, usersPerHour },
  };
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, JSON.stringify(report, null, 2));
  console.log(`Full JSON report written to: ${OUT}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
