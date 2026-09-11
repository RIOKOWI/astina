import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/dependency_injection.dart';
import '../data/datasources/letter_remote_data_source.dart';
import '../data/models/letter_model.dart';
import '../data/models/letter_type_model.dart';

final letterRemoteDataSourceProvider = Provider<LetterRemoteDataSource>((ref) {
  return LetterRemoteDataSource(ref.watch(dioClientProvider));
});

final letterTypesProvider = FutureProvider.autoDispose<List<LetterType>>((
  ref,
) async {
  final ds = ref.watch(letterRemoteDataSourceProvider);
  return ds.getLetterTypes();
});

final myLettersProvider = FutureProvider.autoDispose
    .family<
      List<LetterListItem>,
      ({String? status, int? letterTypeId, int page})
    >((ref, params) async {
      final ds = ref.watch(letterRemoteDataSourceProvider);
      return ds.getMyLetters(
        status: params.status,
        letterTypeId: params.letterTypeId,
        page: params.page,
      );
    });

final letterDetailProvider = FutureProvider.autoDispose.family<Letter, int>((
  ref,
  id,
) async {
  final ds = ref.watch(letterRemoteDataSourceProvider);
  return ds.getLetter(id);
});

final pendingLettersProvider = FutureProvider.autoDispose<List<LetterListItem>>(
  (ref) async {
    final ds = ref.watch(letterRemoteDataSourceProvider);
    return ds.getPendingLetters(page: 1);
  },
);
