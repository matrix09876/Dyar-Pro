// Worker thread: drives a share of the closed-loop virtual users.
// Each virtual user issues a request, waits for the full response, then
// immediately issues the next one, for the whole stage duration. This models
// "think-time = 0" users and gives the maximum sustainable throughput.
import http from 'node:http';
import https from 'node:https';
import { parentPort, workerData } from 'node:worker_threads';
import { performance } from 'node:perf_hooks';

const { target, concurrency, durationMs, method, headers } = workerData;
const url = new URL(target);
const isHttps = url.protocol === 'https:';
const transport = isHttps ? https : http;

// Keep-alive agent so sockets are reused across requests (like real browsers).
const agent = new transport.Agent({
  keepAlive: true,
  maxSockets: concurrency,
  maxFreeSockets: concurrency,
  // Spread sockets so we are not bottlenecked on a single TLS session.
  scheduling: 'lifo',
});

const reqOptions = {
  method,
  agent,
  headers: { 'user-agent': 'dyar-loadtest/1.0', accept: '*/*', ...headers },
};

// Latency reservoir. We keep every sample but cap memory with reservoir
// sampling once we exceed the cap, so percentiles stay representative even
// under millions of requests.
const SAMPLE_CAP = 200000;
const latencies = new Float64Array(SAMPLE_CAP);
let sampleCount = 0;
let seen = 0;

function recordLatency(ms) {
  seen++;
  if (sampleCount < SAMPLE_CAP) {
    latencies[sampleCount++] = ms;
  } else {
    const j = Math.floor(Math.random() * seen);
    if (j < SAMPLE_CAP) latencies[j] = ms;
  }
}

const status = new Map(); // statusCode -> count
let total = 0;
let networkErrors = 0;
let bytes = 0;

function bumpStatus(code) {
  status.set(code, (status.get(code) || 0) + 1);
}

let stop = false;

function doRequest() {
  return new Promise((resolve) => {
    const start = performance.now();
    const req = transport.request(url, reqOptions, (res) => {
      let len = 0;
      res.on('data', (chunk) => {
        len += chunk.length;
      });
      res.on('end', () => {
        const dur = performance.now() - start;
        recordLatency(dur);
        bumpStatus(res.statusCode);
        bytes += len;
        total++;
        resolve();
      });
      res.on('error', () => {
        networkErrors++;
        total++;
        resolve();
      });
    });
    req.on('error', () => {
      networkErrors++;
      total++;
      resolve();
    });
    req.setTimeout(30000, () => {
      req.destroy(new Error('timeout'));
    });
    req.end();
  });
}

async function virtualUser() {
  while (!stop) {
    await doRequest();
  }
}

async function run() {
  const endAt = performance.now() + durationMs;
  const timer = setTimeout(() => {
    stop = true;
  }, durationMs);
  const users = [];
  for (let i = 0; i < concurrency; i++) users.push(virtualUser());
  await Promise.all(users);
  clearTimeout(timer);

  parentPort.postMessage({
    total,
    networkErrors,
    bytes,
    status: Array.from(status.entries()),
    latencies: latencies.slice(0, sampleCount),
    seen,
  });
}

run();
