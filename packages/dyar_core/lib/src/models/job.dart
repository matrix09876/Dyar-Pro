import 'package:cloud_firestore/cloud_firestore.dart';

/// وظيفة شاغرة في لوحة الوظائف — تُنشر من لوحة التحكم.
class Job {
  final String id;
  final String title;
  final String description;
  final String? storeId;
  final String cityId;
  final String type; // driver|kitchen|service|other
  final String? salary;
  final String? contactPhone;
  final String? contactEmail;
  final String status; // open|closed
  final DateTime? createdAt;

  const Job({
    required this.id,
    this.title = '',
    this.description = '',
    this.storeId,
    this.cityId = '',
    this.type = 'other',
    this.salary,
    this.contactPhone,
    this.contactEmail,
    this.status = 'open',
    this.createdAt,
  });

  factory Job.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final contact = (d['contact'] as Map<String, dynamic>?) ?? const {};
    return Job(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      storeId: d['storeId'],
      cityId: d['cityId'] ?? '',
      type: d['type'] ?? 'other',
      salary: d['salary'],
      contactPhone: contact['phone'],
      contactEmail: contact['email'],
      status: d['status'] ?? 'open',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// طلب توظيف (تقديم + سيرة ذاتية نصية) على وظيفة.
class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle; // denormalized لعرض "طلباتي"
  final String applicantUid;
  final String name;
  final String phone;
  final String cvText;
  final String? cvUrl;
  final String status; // new|shortlisted|rejected|hired
  final DateTime? createdAt;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.applicantUid,
    this.jobTitle = '',
    this.name = '',
    this.phone = '',
    this.cvText = '',
    this.cvUrl,
    this.status = 'new',
    this.createdAt,
  });

  factory JobApplication.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return JobApplication(
      id: doc.id,
      jobId: d['jobId'] ?? '',
      jobTitle: d['jobTitle'] ?? '',
      applicantUid: d['applicantUid'] ?? '',
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      cvText: d['cvText'] ?? '',
      cvUrl: d['cvUrl'],
      status: d['status'] ?? 'new',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
