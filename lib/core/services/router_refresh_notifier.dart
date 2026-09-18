import 'package:flutter/material.dart';
import 'auth_state.dart';

final routerRefreshNotifier = _RouterRefreshNotifier();

class _RouterRefreshNotifier extends ChangeNotifier {
  AuthState state = const Unauthenticated();

  void update(AuthState? newState) {
    state = newState ?? const Unauthenticated();
    notifyListeners();
  }
}
