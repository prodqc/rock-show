import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report_model.dart';
import '../repositories/impl/firestore_report_repository.dart';
import '../repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return FirestoreReportRepository();
});

final openReportsProvider = StreamProvider<List<ReportModel>>((ref) {
  return ref.watch(reportRepositoryProvider).watchOpenReports();
});
