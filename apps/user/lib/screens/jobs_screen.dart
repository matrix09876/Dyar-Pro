import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// الوظائف المفتوحة (عامة للتصفّح)
final openJobsProvider = StreamProvider<List<Job>>(
    (ref) => ref.watch(jobServiceProvider).watchOpen());

/// طلبات التوظيف الخاصة بي (كل الحالات)
final myJobApplicationsProvider =
    StreamProvider<List<JobApplication>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const <JobApplication>[]);
  return ref.watch(jobServiceProvider).watchMine(uid);
});

String _jobTypeLabel(S s, String type) => s(switch (type) {
      'driver' => 'jtDriver',
      'kitchen' => 'jtKitchen',
      'service' => 'jtService',
      _ => 'jtOther',
    });

IconData _jobTypeIcon(String type) => switch (type) {
      'driver' => LucideIcons.bike,
      'kitchen' => LucideIcons.chefHat,
      'service' => LucideIcons.wrench,
      _ => LucideIcons.briefcase,
    };

/// التوظيف 💼: تصفّح الوظائف المفتوحة + تقديم بسيرة ذاتية نصية
/// (new → shortlisted/rejected/hired من اللوحة) + تبويب "طلباتي".
class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: Text('💼 ${s('jobsBoard')}'),
          bottom: TabBar(tabs: [
            Tab(text: s('openJobs')),
            Tab(text: s('myApplications')),
          ]),
        ),
        body: const TabBarView(children: [
          _OpenJobsTab(),
          _MyApplicationsTab(),
        ]),
      ),
    );
  }
}

// ===== تبويب الوظائف المفتوحة =====
class _OpenJobsTab extends ConsumerWidget {
  const _OpenJobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final jobsAsync = ref.watch(openJobsProvider);
    final jobs = jobsAsync.value ?? const <Job>[];

    if (jobsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (jobs.isEmpty) {
      return EmptyState(message: s('noData'), icon: LucideIcons.briefcase);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _JobCard(job: jobs[i]),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return GestureDetector(
      onTap: () => _openJobSheet(context, job),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            height: 52, width: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_jobTypeIcon(job.type),
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15.5)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _InfoChip(
                      icon: LucideIcons.tag,
                      text: _jobTypeLabel(s, job.type)),
                  if (job.salary != null && job.salary!.isNotEmpty)
                    _InfoChip(
                        icon: LucideIcons.wallet, text: job.salary!),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(s('applyNow'),
                style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: DyarTokens.inkMuted),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

Future<void> _openJobSheet(BuildContext context, Job job) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _JobDetailsSheet(job: job),
    );

// ===== ورقة التفاصيل + نموذج التقديم (اسم/هاتف/CV نصي) =====
class _JobDetailsSheet extends ConsumerStatefulWidget {
  const _JobDetailsSheet({required this.job});
  final Job job;

  @override
  ConsumerState<_JobDetailsSheet> createState() => _JobDetailsSheetState();
}

class _JobDetailsSheetState extends ConsumerState<_JobDetailsSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _cv = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _name.text = user?.displayName ?? '';
    _phone.text = user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _cv.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = ref.read(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s('signIn'))));
      return;
    }
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _cv.text.trim().isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(jobServiceProvider).apply(
            jobId: widget.job.id,
            jobTitle: widget.job.title,
            applicantUid: uid,
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            cvText: _cv.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s('applicationSent'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s('error'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final job = widget.job;
    // هل سبق التقديم على هذه الوظيفة؟
    final mine = ref.watch(myJobApplicationsProvider).value ??
        const <JobApplication>[];
    final already = mine.any((a) => a.jobId == job.id);

    Widget field(String label, TextEditingController c,
            {TextInputType? type, int lines = 1}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            keyboardType: type,
            maxLines: lines,
            decoration: InputDecoration(labelText: label),
          ),
        );

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                height: 46, width: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_jobTypeIcon(job.type),
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _InfoChip(
                  icon: LucideIcons.tag, text: _jobTypeLabel(s, job.type)),
              if (job.salary != null && job.salary!.isNotEmpty)
                _InfoChip(
                    icon: LucideIcons.wallet,
                    text: '${s('salary')}: ${job.salary}'),
              if (job.cityId.isNotEmpty)
                _InfoChip(icon: LucideIcons.mapPin, text: job.cityId),
            ]),
            if (job.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(s('jobDetails'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 6),
              Text(job.description,
                  style: const TextStyle(
                      color: DyarTokens.inkMuted, fontSize: 13.5)),
            ],
            const Divider(height: 32),
            if (already)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(s('alreadyApplied'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5)),
              )
            else ...[
              Text('📝 ${s('applyNow')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 14),
              field(s('name'), _name),
              field(s('phone'), _phone, type: TextInputType.phone),
              field(s('yourCv'), _cv, lines: 5),
              const SizedBox(height: 8),
              CtaButton(
                label: s('applyNow'),
                icon: LucideIcons.send,
                loading: _busy,
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===== تبويب طلباتي: الحالة بـ StatusChip =====
class _MyApplicationsTab extends ConsumerWidget {
  const _MyApplicationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final mineAsync = ref.watch(myJobApplicationsProvider);
    final mine = mineAsync.value ?? const <JobApplication>[];

    if (mineAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (mine.isEmpty) {
      return EmptyState(message: s('noData'), icon: LucideIcons.fileText);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      itemCount: mine.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final a = mine[i];
        return DyarCard(
          child: Row(children: [
            Container(
              height: 44, width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(LucideIcons.briefcase,
                  color: Color(0xFF1E3A8A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.jobTitle.isEmpty ? s('jobsBoard') : a.jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DyarTokens.inkMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(label: s(a.status), statusKey: a.status),
          ]),
        );
      },
    );
  }
}
