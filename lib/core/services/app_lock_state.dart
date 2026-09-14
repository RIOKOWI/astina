/// Minimal app lock state for router access (no dependency on provider).
class AppLockState {
  final bool enabled;
  final bool locked;
  final bool authenticating;
  final bool canUseBiometric;

  const AppLockState({
    this.enabled = false,
    this.locked = false,
    this.authenticating = false,
    this.canUseBiometric = false,
  });

  AppLockState copyWith({
    bool? enabled,
    bool? locked,
    bool? authenticating,
    bool? canUseBiometric,
  }) {
    return AppLockState(
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
      authenticating: authenticating ?? this.authenticating,
      canUseBiometric: canUseBiometric ?? this.canUseBiometric,
    );
  }
}

/// Global app lock state holder for router access.
final appLockStateHolder = AppLockStateHolder();

class AppLockStateHolder {
  AppLockState? _state;

  AppLockState? get state => _state;

  void update(AppLockState newState) {
    _state = newState;
  }
}
