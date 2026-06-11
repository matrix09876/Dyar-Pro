import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';

/// لوحة الوظائف: تصفّح الوظائف المفتوحة، التقديم بسيرة ذاتية نصية،
/// ومتابعة حالة طلبات المستخدم (new → shortlisted/rejected/hired).
class JobService {
  JobService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Job>> watchOpen() => _db
      .collection('jobs')
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(Job.fromDoc).toList());

  Stream<List<JobApplication>> watchMine(String uid) => _db
      .collection('jobApplications')
      .where('applicantUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(JobApplication.fromDoc).toList());

  /// تقديم طلب توظيف — يبدأ بحالة new دومًا (القرار من الإدارة/التاجر).
  Future<void> apply({
    required String jobId,
    required String jobTitle,
    required String applicantUid,
    required String name,
    required String phone,
    required String cvText,
    String? cvUrl,
  }) =>
      _db.collection('jobApplications').add({
        'jobId': jobId,
        'jobTitle': jobTitle,
        'applicantUid': applicantUid,
        'name': name,
        'phone': phone,
        'cvText': cvText,
        if (cvUrl != null && cvUrl.isNotEmpty) 'cvUrl': cvUrl,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });
}
