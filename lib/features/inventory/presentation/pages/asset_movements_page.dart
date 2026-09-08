import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../inventory/data/models/asset_movement_model.dart';
import '../../data/models/asset_model.dart';
import '../../providers/inventory_provider.dart';

class AssetMovementsPage extends ConsumerStatefulWidget {
  final int assetId;

  const AssetMovementsPage({super.key, required this.assetId});

  @override
  ConsumerState<AssetMovementsPage> createState() => _AssetMovementsPageState();
}

class _AssetMovementsPageState extends ConsumerState<AssetMovementsPage> {
  String? _selectedType;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = MovementFilter(
      type: _selectedType,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      perPage: 50,
    );
    final key = AssetMovementKey(assetId: widget.assetId, filter: filter);
    final movementsAsync = ref.watch(assetMovementsProvider(key));

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Riwayat Pergerakan'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari keterangan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickFilter(
                        label: 'Semua',
                        selected: _selectedType == null,
                        onTap: () => setState(() => _selectedType = null),
                      ),
                      const SizedBox(width: 6),
                      _QuickFilter(
                        label: 'Masuk',
                        selected: _selectedType == 'in',
                        onTap: () => setState(() => _selectedType = 'in'),
                      ),
                      const SizedBox(width: 6),
                      _QuickFilter(
                        label: 'Keluar',
                        selected: _selectedType == 'out',
                        onTap: () => setState(() => _selectedType = 'out'),
                      ),
                      const SizedBox(width: 6),
                      _QuickFilter(
                        label: 'Penyesuaian',
                        selected: _selectedType == 'adjustment',
                        onTap: () =>
                            setState(() => _selectedType = 'adjustment'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: movementsAsync.when(
              loading: () => _buildSkeleton(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (movements) {
                if (movements.isEmpty) {
                  return const Center(child: Text('Belum ada pergerakan'));
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(assetMovementsProvider(key)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: movements.length,
                    itemBuilder: (context, index) {
                      final m = movements[index];
                      return _MovementCard(movement: m);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final AssetMovementModel movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _typeColor(movement.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _typeIcon(movement.type),
              color: _typeColor(movement.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description ?? '-',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor(movement.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        movement.typeLabel,
                        style: TextStyle(
                          color: _typeColor(movement.type),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${movement.formattedDate} ${movement.formattedTime}',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                if (movement.createdBy != null)
                  Text(
                    'Oleh: ${movement.createdBy!.name}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            _signedQty,
            style: TextStyle(
              color: _typeColor(movement.type),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String get _signedQty {
    if (movement.type == 'out') return '-${movement.quantity}';
    if (movement.type == 'adjustment') {
      return movement.quantity < 0
          ? '${movement.quantity}'
          : '+${movement.quantity}';
    }
    return '+${movement.quantity}';
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

class _QuickFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.dark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
