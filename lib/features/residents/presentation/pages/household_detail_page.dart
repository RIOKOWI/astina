import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/admin_household_model.dart';
import '../../data/models/admin_resident_model.dart';
import '../../providers/household_admin_provider.dart';
import '../../providers/resident_admin_provider.dart';

class HouseholdDetailPage extends ConsumerWidget {
  final int householdId;

  const HouseholdDetailPage({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(householdDetailProvider(householdId));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail Keluarga'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/households/$householdId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddMemberDialog(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (household) => _buildContent(context, ref, household),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AdminHousehold household,
  ) {
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(householdDetailProvider(householdId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(household),
            const SizedBox(height: 20),
            _buildAddressCard(household),
            const SizedBox(height: 24),
            const Text(
              'Anggota Keluarga',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 12),
            if (household.members == null || household.members!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Belum ada anggota',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              )
            else
              ...household.members!.map(
                (m) => _buildMemberCard(context, ref, m, household),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AdminHousehold household) {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.home, color: AppColors.dark, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No. KK: ${household.noKk}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                if (household.headResident != null)
                  Text(
                    'Kepala: ${household.headResident!.fullName}',
                    style: const TextStyle(fontSize: 14, color: AppColors.grey),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: household.status == 'active'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              household.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: household.status == 'active'
                    ? AppColors.success
                    : AppColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AdminHousehold household) {
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
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Alamat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            household.address,
            style: const TextStyle(fontSize: 14, color: AppColors.dark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChip('RT ${household.rt}'),
              const SizedBox(width: 8),
              _buildChip('RW ${household.rw}'),
              if (household.postalCode != null) ...[
                const SizedBox(width: 8),
                _buildChip(household.postalCode!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.dark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.dark,
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    WidgetRef ref,
    AdminHouseholdMember m,
    AdminHousehold household,
  ) {
    final isHead = m.relationship == 'head';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHead
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isHead
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.dark.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                m.fullName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isHead ? AppColors.primary : AppColors.dark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    if (isHead) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'KK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  m.relationshipLabel,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                if (m.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    m.phone!,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ],
            ),
          ),
          if (!isHead)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
              ),
              onPressed: () =>
                  _confirmRemoveMember(context, ref, m, household.id),
            ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    AdminHouseholdMember m,
    int householdId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluarkan Anggota'),
        content: Text('Keluarkan ${m.fullName} dari keluarga ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(householdAdminDataSourceProvider)
                    .removeMember(householdId, m.id);
                ref.invalidate(householdDetailProvider(householdId));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    String relationship = 'spouse';
    DateTime? joinedAt;
    bool isSubmitting = false;
    bool isSearching = false;
    AdminResidentListItem? selectedResident;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, innerSetState) {
          return AlertDialog(
            title: const Text('Tambah Anggota Keluarga'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<AdminResidentListItem>(
                      displayStringForOption: (r) => '${r.fullName} (${r.nik})',
                      optionsBuilder: (txt) async {
                        if (txt.text.trim().length < 2) return [];
                        innerSetState(() => isSearching = true);
                        try {
                          final ds = ref.read(residentAdminDataSourceProvider);
                          final (list, _) = await ds.getResidents(
                            search: txt.text.trim(),
                            page: 1,
                          );
                          if (dialogCtx.mounted) {
                            innerSetState(() {
                              isSearching = false;
                            });
                          }
                          return list;
                        } catch (_) {
                          if (dialogCtx.mounted) {
                            innerSetState(() => isSearching = false);
                          }
                          return <AdminResidentListItem>[];
                        }
                      },
                      onSelected: (r) =>
                          innerSetState(() => selectedResident = r),
                      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmitted) {
                        return TextField(
                          controller: ctrl,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Cari Warga (nama/NIK) *',
                            hintText: 'Ketik nama atau NIK...',
                            border: const OutlineInputBorder(),
                            suffixIcon: isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                      optionsViewBuilder: (ctx, onSelect, options) => Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: options.isEmpty
                                ? const ListTile(
                                    dense: true,
                                    title: Text('Tidak ada hasil'),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (ctx, i) {
                                      final r = options.elementAt(i);
                                      return ListTile(
                                        dense: true,
                                        title: Text(r.fullName),
                                        subtitle: Text('NIK: ${r.nik}'),
                                        onTap: () => onSelect(r),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (selectedResident != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${selectedResident!.fullName} (${selectedResident!.nik})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  innerSetState(() => selectedResident = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: relationship,
                      decoration: const InputDecoration(
                        labelText: 'Hubungan *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'spouse',
                          child: Text('Pasangan'),
                        ),
                        DropdownMenuItem(value: 'child', child: Text('Anak')),
                        DropdownMenuItem(
                          value: 'parent',
                          child: Text('Orang Tua'),
                        ),
                        DropdownMenuItem(
                          value: 'sibling',
                          child: Text('Saudara'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Lainnya'),
                        ),
                      ],
                      onChanged: (v) => innerSetState(() => relationship = v!),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: dialogCtx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) innerSetState(() => joinedAt = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Masuk (opsional)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(
                          joinedAt != null
                              ? '${joinedAt!.day}/${joinedAt!.month}/${joinedAt!.year}'
                              : '-',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSubmitting || selectedResident == null
                    ? null
                    : () async {
                        innerSetState(() => isSubmitting = true);
                        try {
                          final ds = ref.read(householdAdminDataSourceProvider);
                          await ds.addMember(householdId, {
                            'resident_id': selectedResident!.id,
                            'relationship': relationship,
                            if (joinedAt != null)
                              'joined_at': joinedAt!
                                  .toIso8601String()
                                  .split('T')
                                  .first,
                          });
                          ref.invalidate(householdDetailProvider(householdId));
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Anggota berhasil ditambahkan'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          innerSetState(() => isSubmitting = false);
                          String msg;
                          if (e.toString().contains('409')) {
                            msg =
                                'Warga ini sudah terdaftar di keluarga lain atau sudah menjadi anggota';
                          } else if (e.toString().contains('422')) {
                            msg =
                                'Data tidak valid. Pastikan warga belum terdaftar.';
                          } else {
                            msg = 'Gagal: $e';
                          }
                          if (dialogCtx.mounted) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }
}
