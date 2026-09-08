import '../../features/auth/data/models/user_model.dart';

sealed class AuthState {
  const AuthState();
  bool get isAuthenticated => this is Authenticated;
  UserModel? get user => switch (this) {
    Authenticated(:final user) => user,
    _ => null,
  };
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  @override
  final UserModel user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}
