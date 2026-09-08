import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/complaint_remote_data_source.dart';

final complaintAttachmentRemoteDataSourceProvider =
    Provider<ComplaintRemoteDataSource>((ref) {
      final dioClient = ref.watch(dioClientProvider);
      return ComplaintRemoteDataSource(dioClient);
    });
