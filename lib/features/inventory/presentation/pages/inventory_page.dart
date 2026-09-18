import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../data/models/asset_model.dart';
import '../../providers/inventory_provider.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _searchController = TextEditingController();
  String? _categoryFilter;
  String? _statusFilter;
  String? _conditionFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() => ref
      .read(inventoryListProvider.notifier)
      .load(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        category: _categoryFilter,
        condition: _conditionFilter,
        status: _statusFilter,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryListProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Aset / Inventaris'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari aset...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => ref
                  .read(inventoryListProvider.notifier)
                  .load(
                    search: v.isEmpty ? null : v,
                    category: _categoryFilter,
                    condition: _conditionFilter,
                    status: _statusFilter,
                  ),
            ),
          ),
          if (_categoryFilter != null ||
              _statusFilter != null ||
              _conditionFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_categoryFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_categoryFilter!),
                        onDeleted: () {
                          setState(() => _categoryFilter = null);
                          _load();
                        },
                      ),
                    ),
                  if (_statusFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_statusFilterLabel(_statusFilter!)),
                        onDeleted: () {
                          setState(() => _statusFilter = null);
                          _load();
                        },
                      ),
                    ),
                  if (_conditionFilter != null)
                    Chip(
                      label: Text(_conditionFilterLabel(_conditionFilter!)),
                      onDeleted: () {
                        setState(() => _conditionFilter = null);
                        _load();
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: state.error != null
                  ? _buildError(state.error!)
                  : state.assets.isEmpty && !state.isLoading
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.assets.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.assets.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          ref
                              .read(inventoryListProvider.notifier)
                              .loadMore(
                                search: _searchController.text.isEmpty
                                    ? null
                                    : _searchController.text,
                                category: _categoryFilter,
                                condition: _conditionFilter,
                                status: _statusFilter,
                              );
                          return const SizedBox.shrink();
                        }
                        return _AssetCard(
                          asset: state.assets[index],
                          onTap: () => context.push(
                            '/inventory/${state.assets[index].id}',
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada aset',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String msg) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat aset',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  friendlyErrorMessage(msg),
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      ],
    );
  }

  String _statusFilterLabel(String s) {
    switch (s) {
      case 'available':
        return 'Tersedia';
      case 'in_use':
        return 'Dipakai';
      case 'maintenance':
        return 'Perbaikan';
      case 'retired':
        return 'Nonaktif';
      default:
        return s;
    }
  }

  String _conditionFilterLabel(String c) {
    switch (c) {
      case 'new':
        return 'Baru';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      case 'poor':
        return 'Rusak';
      default:
        return c;
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kondisi',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('Semua', null, (v) {
                  setState(() => _conditionFilter = v);
                }),
                _filterChip(
                  'Baru',
                  'new',
                  (v) => setState(() => _conditionFilter = v),
                ),
                _filterChip(
                  'Baik',
                  'good',
                  (v) => setState(() => _conditionFilter = v),
                ),
                _filterChip(
                  'Cukup',
                  'fair',
                  (v) => setState(() => _conditionFilter = v),
                ),
                _filterChip(
                  'Rusak',
                  'poor',
                  (v) => setState(() => _conditionFilter = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  'Semua',
                  null,
                  (v) => setState(() => _statusFilter = v),
                ),
                _filterChip(
                  'Tersedia',
                  'available',
                  (v) => setState(() => _statusFilter = v),
                ),
                _filterChip(
                  'Dipakai',
                  'in_use',
                  (v) => setState(() => _statusFilter = v),
                ),
                _filterChip(
                  'Perbaikan',
                  'maintenance',
                  (v) => setState(() => _statusFilter = v),
                ),
                _filterChip(
                  'Nonaktif',
                  'retired',
                  (v) => setState(() => _statusFilter = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Terapkan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    String label,
    String? value,
    void Function(String?) onSelected,
  ) {
    final isSelected =
        value == null ||
        (_conditionFilter == value) ||
        (_statusFilter == value);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset, required this.onTap});

  final Asset asset;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (asset.status) {
      case 'available':
        return AppColors.primary;
      case 'in_use':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return AppColors.grey;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    asset.code,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    asset.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              asset.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            if (asset.description != null) ...[
              const SizedBox(height: 4),
              Text(
                asset.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    asset.category,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.inventory_2, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${asset.quantity} ${asset.unit}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    asset.conditionLabel,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
