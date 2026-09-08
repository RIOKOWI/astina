import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/inventory_provider.dart';

class AssetDetailPage extends ConsumerWidget {
  final int assetId;

  const AssetDetailPage({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(assetDetailProvider(assetId));
    final mutationState = ref.watch(inventoryNotifierProvider);
    final isProcessing = mutationState.valueOrNull?.isProcessing ?? false;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Detail Asset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (asset) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(asset),
              const SizedBox(height: 16),
              _buildInfoCard(asset),
              const SizedBox(height: 16),
              _buildMovementsCard(context, ref, asset),
              const SizedBox(height: 16),
              if (!asset.isRetired)
                _buildActionsCard(context, ref, asset, isProcessing),
            ],
          ),
        ),
      ),
      floatingActionButton:
          detailAsync.valueOrNull != null && !detailAsync.value!.isRetired
          ? FloatingActionButton.extended(
              onPressed: isProcessing
                  ? null
                  : () => _showMovementDialog(context, ref, detailAsync.value!),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              label: const Text(
                'Catat Pergerakan',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            asset.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            asset.code,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _stockColor(asset).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${asset.quantity} ${asset.unit}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(asset.status).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  asset.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(asset) {
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
            'Informasi Asset',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _infoRow('Kode', asset.code),
          _infoRow('Nama', asset.name),
          _infoRow('Kategori', asset.category),
          _infoRow('Kondisi', asset.conditionLabel),
          _infoRow('Satuan', asset.unit),
          _infoRow('Status', asset.statusLabel),
          if (asset.description != null)
            _infoRow('Deskripsi', asset.description!),
          if (asset.purchasePrice != null)
            _infoRow('Harga Beli', asset.formattedPurchasePrice),
          if (asset.purchaseDate != null)
            _infoRow('Tgl Beli', asset.formattedPurchaseDate),
        ],
      ),
    );
  }

  Widget _buildMovementsCard(BuildContext context, WidgetRef ref, asset) {
    final movements = asset.recentMovements ?? [];
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
          Row(
            children: [
              Text(
                'Riwayat Pergerakan',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/inventory/$assetId/movements'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (movements.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Belum ada pergerakan',
                  style: TextStyle(color: AppColors.grey),
                ),
              ),
            )
          else
            ...movements.take(5).map((m) => _MovementItem(movement: m)),
        ],
      ),
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    WidgetRef ref,
    asset,
    bool isProcessing,
  ) {
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
            'Aksi',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isProcessing
                  ? null
                  : () => _confirmRetire(context, ref, asset),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Nonaktifkan Asset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return AppColors.success;
      case 'in_use':
        return AppColors.primary;
      case 'maintenance':
        return AppColors.warning;
      case 'retired':
        return AppColors.grey;
      default:
        return AppColors.grey;
    }
  }

  Color _stockColor(asset) {
    if (asset.isOutOfStock) return AppColors.error;
    if (asset.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final asset = ref.read(assetDetailProvider(assetId)).valueOrNull;
    if (asset == null) return;

    final nameController = TextEditingController(text: asset.name);
    final categoryController = TextEditingController(text: asset.category);
    final descController = TextEditingController(text: asset.description ?? '');
    String? condition = asset.condition;
    String? status = asset.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Asset',
                  style: AppTextStyles.headline2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  decoration: const InputDecoration(labelText: 'Kondisi'),
                  items: const [
                    DropdownMenuItem(value: 'new', child: Text('Baru')),
                    DropdownMenuItem(value: 'good', child: Text('Baik')),
                    DropdownMenuItem(value: 'fair', child: Text('Cukup')),
                    DropdownMenuItem(value: 'poor', child: Text('Rusak')),
                  ],
                  onChanged: (v) => setState(() => condition = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Tersedia'),
                    ),
                    DropdownMenuItem(value: 'in_use', child: Text('Dipakai')),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Perbaikan'),
                    ),
                  ],
                  onChanged: (v) => setState(() => status = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ref
                            .read(inventoryNotifierProvider.notifier)
                            .updateAsset(assetId, {
                              'name': nameController.text,
                              'category': categoryController.text,
                              'description': descController.text,
                              'condition': condition,
                              'status': status,
                            });
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Asset berhasil diperbarui'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gagal memperbarui asset'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRetire(BuildContext context, WidgetRef ref, dynamic asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Asset?'),
        content: Text(
          'Asset "${asset.name}" akan dinonaktifkan. Pergerakan stock tidak bisa dilakukan setelah dinonaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(inventoryNotifierProvider.notifier)
                    .retireAsset(assetId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Asset berhasil dinonaktifkan'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menonaktifkan asset'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
  }

  void _showMovementDialog(BuildContext context, WidgetRef ref, dynamic asset) {
    final qtyController = TextEditingController();
    final descController = TextEditingController();
    String type = 'in';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catat Pergerakan Stok',
                style: AppTextStyles.headline2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Stok saat ini: ${asset.quantity} ${asset.unit}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Tipe Pergerakan', style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MovementTypeChip(
                    label: 'Masuk',
                    icon: Icons.add,
                    selected: type == 'in',
                    onTap: () => setState(() => type = 'in'),
                  ),
                  const SizedBox(width: 8),
                  _MovementTypeChip(
                    label: 'Keluar',
                    icon: Icons.remove,
                    selected: type == 'out',
                    onTap: () => setState(() => type = 'out'),
                  ),
                  const SizedBox(width: 8),
                  _MovementTypeChip(
                    label: 'Penyesuaian',
                    icon: Icons.tune,
                    selected: type == 'adjustment',
                    onTap: () => setState(() => type = 'adjustment'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final qty = int.tryParse(qtyController.text);
                    if (qty == null || qty == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Jumlah harus diisi dengan angka'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(inventoryNotifierProvider.notifier)
                          .createMovement(assetId, {
                            'type': type,
                            'quantity': qty,
                            'description': descController.text.isNotEmpty
                                ? descController.text
                                : null,
                          });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pergerakan berhasil dicatat'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal mencatat: ${e.toString()}'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Catat'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  final dynamic movement;

  const _MovementItem({required this.movement});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor(movement.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _typeIcon(movement.type),
              color: _typeColor(movement.type),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description ?? movement.typeLabel,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
                Text(
                  '${movement.formattedDate} • ${movement.createdBy?.name ?? '-'}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${movement.type == 'out' || (movement.type == 'adjustment' && movement.quantity < 0) ? '-' : '+'}${movement.quantity.abs()}',
            style: TextStyle(
              color: _typeColor(movement.type),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'in':
        return AppColors.success;
      case 'out':
        return AppColors.error;
      case 'adjustment':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'in':
        return Icons.add;
      case 'out':
        return Icons.remove;
      case 'adjustment':
        return Icons.tune;
      default:
        return Icons.swap_horiz;
    }
  }
}

class _MovementTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MovementTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.dark,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.dark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
