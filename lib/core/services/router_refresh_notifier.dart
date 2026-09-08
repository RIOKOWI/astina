import 'package:flutter/material.dart';
import 'auth_state.dart';

final routerRefreshNotifier = _RouterRefreshNotifier();

class _RouterRefreshNotifier extends ChangeNotifier {
  AuthState? state;

  void update(AuthState? newState) {
    state = newState;
    notifyListeners();
  }
}
