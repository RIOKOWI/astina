import 'package:flutter/material.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class MenuItemModel {
  const MenuItemModel({
    required this.icon,
    required this.label,
    required this.route,
    this.roles = const [UserRole.warga, UserRole.rt, UserRole.bendahara],
  });

  final IconData icon;
  final String label;
  final String route;
  final List<UserRole> roles;
}

abstract final class MenuConfig {
  static const warga = [
    MenuItemModel(
      icon: Icons.home_outlined,
      label: 'Beranda',
      route: '/dashboard',
    ),
    MenuItemModel(
      icon: Icons.campaign_outlined,
      label: 'Aktivitas',
      route: '/activities',
      roles: [UserRole.warga, UserRole.rt, UserRole.bendahara],
    ),
    MenuItemModel(
      icon: Icons.report_outlined,
      label: 'Pengaduan',
      route: '/complaints',
      roles: [UserRole.warga],
    ),
    MenuItemModel(
      icon: Icons.mail_outlined,
      label: 'Surat',
      route: '/letters',
      roles: [UserRole.warga],
    ),
    MenuItemModel(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Iuran & Bayar',
      route: '/finance',
      roles: [UserRole.warga],
    ),
    MenuItemModel(
      icon: Icons.family_restroom_outlined,
      label: 'Data Keluarga Saya',
      route: '/my/household',
      roles: [UserRole.warga],
    ),
    MenuItemModel(
      icon: Icons.person_outlined,
      label: 'Data Diri Saya',
      route: '/my/resident',
      roles: [UserRole.warga],
    ),
    MenuItemModel(
      icon: Icons.badge_outlined,
      label: 'Dokumen Saya',
      route: '/my/documents',
      roles: [UserRole.warga],
    ),
    MenuItemModel(
      icon: Icons.warning_amber_outlined,
      label: 'SOS',
      route: '/sos',
    ),
    MenuItemModel(
      icon: Icons.notifications_outlined,
      label: 'Notifikasi',
      route: '/notifications',
    ),
    MenuItemModel(
      icon: Icons.person_outlined,
      label: 'Profil',
      route: '/profile',
    ),
  ];

  static const rt = [
    MenuItemModel(
      icon: Icons.home_outlined,
      label: 'Beranda',
      route: '/dashboard',
    ),
    MenuItemModel(
      icon: Icons.people_outlined,
      label: 'Data Warga',
      route: '/residents',
      roles: [UserRole.rt],
    ),
    MenuItemModel(
      icon: Icons.family_restroom_outlined,
      label: 'Data Keluarga',
      route: '/households',
      roles: [UserRole.rt],
    ),
    MenuItemModel(
      icon: Icons.admin_panel_settings_outlined,
      label: 'User Admin',
      route: '/users',
      roles: [UserRole.rt],
    ),
    MenuItemModel(
      icon: Icons.campaign_outlined,
      label: 'Aktivitas',
      route: '/activities',
      roles: [UserRole.rt],
    ),
    MenuItemModel(
      icon: Icons.report_outlined,
      label: 'Pengaduan',
      route: '/complaints',
      roles: [UserRole.rt],
    ),
    MenuItemModel(
      icon: Icons.mail_outlined,
      label: 'Surat',
      route: '/letters',
      roles: [UserRole.rt],
    ),
    MenuItemModel(
      icon: Icons.inventory_2_outlined,
      label: 'Aset',
      route: '/inventory',
      roles: [UserRole.rt],
    ),
    MenuItemModel(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Keuangan',
      route: '/finance',
      roles: [UserRole.rt],
    ),
    MenuItemModel(
      icon: Icons.warning_amber_outlined,
      label: 'SOS',
      route: '/sos',
    ),
    MenuItemModel(
      icon: Icons.notifications_outlined,
      label: 'Notifikasi',
      route: '/notifications',
    ),
    MenuItemModel(
      icon: Icons.person_outlined,
      label: 'Profil',
      route: '/profile',
    ),
  ];

  static const bendahara = [
    MenuItemModel(
      icon: Icons.home_outlined,
      label: 'Beranda',
      route: '/dashboard',
    ),
    MenuItemModel(
      icon: Icons.payments_outlined,
      label: 'Pembayaran',
      route: '/finance/payments/pending',
      roles: [UserRole.bendahara],
    ),
    MenuItemModel(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Kas RT',
      route: '/finance',
      roles: [UserRole.bendahara],
    ),
    MenuItemModel(
      icon: Icons.warning_amber_outlined,
      label: 'SOS',
      route: '/sos',
    ),
    MenuItemModel(
      icon: Icons.notifications_outlined,
      label: 'Notifikasi',
      route: '/notifications',
    ),
    MenuItemModel(
      icon: Icons.person_outlined,
      label: 'Profil',
      route: '/profile',
    ),
  ];
}
