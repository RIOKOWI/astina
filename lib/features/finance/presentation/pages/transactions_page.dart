import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/finance_provider.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String? _typeFilter;
  String? _categoryFilter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void _load() => ref
      .read(transactionListProvider.notifier)
      .load(
        type: _typeFilter,
        category: _categoryFilter,
        dateFrom: _dateRange?.start.toIso8601String().split('T').first,
        dateTo: _dateRange?.end.toIso8601String().split('T').first,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider);
    final role = ref.watch(currentUserRoleProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_typeFilter != null ||
              _categoryFilter != null ||
              _dateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_typeFilter != null)
                    Chip(
                      label: Text(
                        _typeFilter == 'income' ? 'Pemasukan' : 'Pengeluaran',
                      ),
                      onDeleted: () {
                        setState(() => _typeFilter = null);
                        _load();
                      },
                    ),
                  if (_categoryFilter != null)
                    Chip(
                      label: Text(_categoryFilter!),
                      onDeleted: () {
                        setState(() => _categoryFilter = null);
                        _load();
                      },
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                        '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                      ),
                      onDeleted: () {
                        setState(() => _dateRange = null);
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
                  : state.transactions.isEmpty && !state.isLoading
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          state.transactions.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.transactions.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          ref
                              .read(transactionListProvider.notifier)
                              .loadMore(
                                type: _typeFilter,
                                category: _categoryFilter,
                                dateFrom: _dateRange?.start
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                                dateTo: _dateRange?.end
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                              );
                          return const SizedBox.shrink();
                        }
                        return _TransactionCard(
                          transaction: state.transactions[index],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: role == UserRole.rt || role == UserRole.bendahara
          ? FloatingActionButton(
              onPressed: () => context.push('/finance/transactions/create'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Belum ada transaksi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat transaksi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  friendlyErrorMessage(message),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
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

  Future<void> _showFilterSheet() async {
    String? selectedType = _typeFilter;
    DateTimeRange? selectedRange = _dateRange;
    final categoryController = TextEditingController(
      text: _categoryFilter ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tipe',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Semua'),
                      selected: selectedType == null,
                      onSelected: (_) =>
                          setSheetState(() => selectedType = null),
                    ),
                    ChoiceChip(
                      label: const Text('Pemasukan'),
                      selected: selectedType == 'income',
                      onSelected: (_) =>
                          setSheetState(() => selectedType = 'income'),
                    ),
                    ChoiceChip(
                      label: const Text('Pengeluaran'),
                      selected: selectedType == 'expense',
                      onSelected: (_) =>
                          setSheetState(() => selectedType = 'expense'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'Contoh: operasional',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tanggal',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: sheetContext,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: selectedRange,
                          );
                          if (range != null) {
                            setSheetState(() => selectedRange = range);
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          selectedRange == null
                              ? 'Pilih Tanggal'
                              : '${selectedRange!.start.day}/${selectedRange!.start.month} - ${selectedRange!.end.day}/${selectedRange!.end.month}',
                        ),
                      ),
                    ),
                    if (selectedRange != null)
                      IconButton(
                        onPressed: () =>
                            setSheetState(() => selectedRange = null),
                        icon: const Icon(Icons.close),
                        tooltip: 'Hapus tanggal',
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final category = categoryController.text.trim();
                      setState(() {
                        _typeFilter = selectedType;
                        _categoryFilter = category.isEmpty ? null : category;
                        _dateRange = selectedRange;
                      });
                      Navigator.pop(sheetContext);
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
        ),
      ),
    );
    categoryController.dispose();
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final dynamic transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.primary : AppColors.error;
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ??
                      (isIncome ? 'Pemasukan' : 'Pengeluaran'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(transaction.transactionAt)} • ${transaction.category}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_formatCurrency(transaction.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
