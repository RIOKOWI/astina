import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../providers/letter_provider.dart';

class LetterReviewPage extends ConsumerStatefulWidget {
  final int letterId;

  const LetterReviewPage({super.key, required this.letterId});

  @override
  ConsumerState<LetterReviewPage> createState() => _LetterReviewPageState();
}

class _LetterReviewPageState extends ConsumerState<LetterReviewPage> {
  final _rejectController = TextEditingController();
  bool _showRejectForm = false;

  @override
  void dispose() {
    _rejectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(letterDetailProvider(widget.letterId));
    final stateAsync = ref.watch(rtLetterNotifierProvider);

    final isProcessing = stateAsync.valueOrNull?.isProcessing ?? false;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Tinjau Surat'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (letter) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusHeader(letter),
              const SizedBox(height: 16),
              _buildInfoCard(letter),
              const SizedBox(height: 16),
              if (letter.fieldValues != null &&
                  letter.fieldValues!.isNotEmpty) ...[
                _buildFieldValuesCard(letter),
                const SizedBox(height: 16),
              ],
              if (letter.purpose != null && letter.purpose!.isNotEmpty) ...[
                _buildPurposeCard(letter),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              if (_showRejectForm)
                _buildRejectForm(isProcessing)
              else
                _buildActionButtons(context, isProcessing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(letter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(
            letter.referenceNo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            letter.letterType?.name ?? 'Surat',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Diajukan: ${letter.resident?.name ?? '-'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(letter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pemohon', style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            letter.resident?.name ?? '-',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (letter.resident?.address != null) ...[
            const SizedBox(height: 2),
            Text(letter.resident!.address!, style: AppTextStyles.bodySmall),
          ],
          if (letter.resident?.phone != null) ...[
            const SizedBox(height: 2),
            Text(letter.resident!.phone!, style: AppTextStyles.bodySmall),
          ],
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diajukan', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    Text(letter.formattedDate, style: AppTextStyles.body),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waktu', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    Text(letter.formattedTime, style: AppTextStyles.body),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldValuesCard(letter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Pengajuan',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...letter.fieldValues!.map<Widget>(
            (fv) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(fv.label, style: AppTextStyles.bodySmall),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(fv.value, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeCard(letter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tujuan',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(letter.purpose!, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildRejectForm(bool isProcessing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alasan Penolakan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rejectController,
            decoration: const InputDecoration(
              hintText: 'Jelaskan alasan penolakan...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing
                      ? null
                      : () => setState(() => _showRejectForm = false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing || _rejectController.text.isEmpty
                      ? null
                      : () => _rejectLetter(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Tolak'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isProcessing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isProcessing ? null : () => _approveLetter(context),
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: const Text('Setujui & Buat Dokumen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isProcessing
                  ? null
                  : () => setState(() => _showRejectForm = true),
              icon: const Icon(Icons.close),
              label: const Text('Tolak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveLetter(BuildContext context) async {
    final success = await ref
        .read(rtLetterNotifierProvider.notifier)
        .approveLetter(widget.letterId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surat berhasil disetujui!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(rtLetterNotifierProvider).valueOrNull?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${err ?? 'Coba lagi'}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectLetter() async {
    if (_rejectController.text.isEmpty) return;
    final success = await ref
        .read(rtLetterNotifierProvider.notifier)
        .rejectLetter(widget.letterId, _rejectController.text);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surat berhasil ditolak.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(rtLetterNotifierProvider).valueOrNull?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${err ?? 'Coba lagi'}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
