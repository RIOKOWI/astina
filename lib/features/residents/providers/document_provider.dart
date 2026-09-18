import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/me_document_data_source.dart';
import '../data/models/document_model.dart';

final meDocumentDataSourceProvider = Provider<MeDocumentDataSource>((ref) {
  return MeDocumentDataSource(ref.watch(dioClientProvider));
});

final meDocumentsProvider = FutureProvider.autoDispose<MeDocument?>((
  ref,
) async {
  final ds = ref.watch(meDocumentDataSourceProvider);
  return ds.getMyDocuments();
});
