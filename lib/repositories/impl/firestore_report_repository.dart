import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/report_model.dart';
import '../report_repository.dart';

class FirestoreReportRepository implements ReportRepository {
  final FirebaseFirestore _db;

  FirestoreReportRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _reports => _db.collection('reports');

  @override
  Future<String> createReport(ReportModel report) async {
    final ref = _reports.doc();
    final data = report.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  @override
  Stream<List<ReportModel>> watchOpenReports({int limit = 100}) {
    return _reports
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReportModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String adminUid,
  }) async {
    await _reports.doc(reportId).update({
      'status': status,
      'resolvedBy': adminUid,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
