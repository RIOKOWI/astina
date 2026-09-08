import 'package:flutter/material.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerRefreshNotifier = _RouterRefreshNotifier();

class _RouterRefreshNotifier extends ChangeNotifier {
  AuthState? state;

  void update(AuthState? newState) {
    state = newState;
    notifyListeners();
  }
}
