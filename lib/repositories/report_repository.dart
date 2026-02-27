import '../models/report_model.dart';

abstract class ReportRepository {
  Future<String> createReport(ReportModel report);
  Stream<List<ReportModel>> watchOpenReports({int limit = 100});
  Future<void> updateReportStatus({
    required String reportId,
    required String status, // resolved | dismissed
    required String adminUid,
  });
}
