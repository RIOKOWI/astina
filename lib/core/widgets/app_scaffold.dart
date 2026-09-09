import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_drawer.dart';

/// Wrapper that adds drawer to any page without duplicating Scaffold code.
/// Use this instead of raw Scaffold in pages that need the drawer.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: actions,
      ),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
