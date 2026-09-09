import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/asset_model.dart';
import '../../providers/inventory_provider.dart';

class AssetDetailPage extends ConsumerStatefulWidget {
  final int assetId;

  const AssetDetailPage({super.key, required this.assetId});

  @override
  ConsumerState<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends ConsumerState<AssetDetailPage> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(assetDetailProvider(widget.assetId));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail Aset'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/inventory/${widget.assetId}/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Nonaktifkan Aset',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: detailAsync.when(
        data: (asset) => _buildContent(asset),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/inventory/${widget.assetId}/movement'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.swap_vert, color: Colors.white),
        label:
            const Text('Catat Pergerakan', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildContent(Asset asset) {
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(assetDetailProvider(widget.assetId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(asset),
            const SizedBox(height: 16),
            _buildStockCard(asset),
            const SizedBox(height: 16),
            _buildInfoCard(asset),
            if (asset.description != null) ...[
              const SizedBox(height: 16),
              _buildDescriptionCard(asset),
            ],
            const SizedBox(height: 16),
            _buildMovementsSection(asset),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Asset asset) {
    Color statusColor;
    switch (asset.status) {
      case 'available':
        statusColor = AppColors.primary;
        break;
      case 'in_use':
        statusColor = Colors.blue;
        break;
      case 'maintenance':
        statusColor = Colors.orange;
        break;
      case 'retired':
        statusColor = AppColors.grey;
        break;
      default:
        statusColor = AppColors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(asset.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    )),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(asset.conditionLabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(asset.code,
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 4),
          Text(asset.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.category_outlined,
                  size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(asset.category,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.grey)),
              const SizedBox(width: 16),
              const Icon(Icons.straighten, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text('${asset.quantity} ${asset.unit}',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Asset asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Stok Saat Ini',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '${asset.quantity} ${asset.unit}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Asset asset) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark)),
          const SizedBox(height: 12),
          if (asset.purchasePrice != null)
            _infoRow('Harga Beli', 'Rp ${asset.purchasePrice}'),
          if (asset.purchaseDate != null) ...[
            const SizedBox(height: 8),
            _infoRow('Tanggal Beli', asset.purchaseDate!),
          ],
          const SizedBox(height: 8),
          _infoRow('Kode', asset.code),
          const SizedBox(height: 8),
          _infoRow('Kategori', asset.category),
          const SizedBox(height: 8),
          _infoRow('Kondisi', asset.conditionLabel),
          const SizedBox(height: 8),
          _infoRow('Status', asset.statusLabel),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Asset asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deskripsi',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          Text(asset.description!,
              style: const TextStyle(fontSize: 14, color: AppColors.dark)),
        ],
      ),
    );
  }

  Widget _buildMovementsSection(Asset asset) {
    final movements = asset.recentMovements ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Riwayat Pergerakan',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.dark)),
        const SizedBox(height: 12),
        if (movements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('Belum ada pergerakan',
                  style: TextStyle(color: AppColors.grey)),
            ),
          )
        else
          ...movements
              .map((m) => _MovementTile(movement: m, unit: asset.unit)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark)),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Aset'),
        content: const Text(
            'Aset akan dinonaktifkan. Riwayat pergerakan tetap tersimpan. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(inventoryDataSourceProvider).deleteAsset(widget.assetId);
        if (mounted) {
          context.go('/inventory');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aset berhasil dinonaktifkan'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement, required this.unit});

  final AssetMovement movement;
  final String unit;

  Color get _typeColor {
    switch (movement.type) {
      case 'in':
        return AppColors.primary;
      case 'out':
        return AppColors.dark;
      case 'adjustment':
        return Colors.orange;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive =
        movement.type == 'in' || (movement.type == 'adjustment' && movement.quantity > 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              movement.type == 'in'
                  ? Icons.arrow_downward
                  : movement.type == 'out'
                      ? Icons.arrow_upward
                      : Icons.swap_vert,
              color: _typeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description ?? movement.typeLabel,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.dark),
                ),
                Text(
                  '${_formatDate(movement.movementAt)} • ${movement.createdBy?.name ?? '-'}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${movement.quantity} $unit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _typeColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
