part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

// Bắn event này khi đăng nhập/đăng ký thành công
class AuthUserChanged extends AuthEvent {
  final User? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

// Bắn event này khi cần xác thực OTP
class AuthNeedsVerification extends AuthEvent {
  final String email;
  const AuthNeedsVerification(this.email);
  @override
  List<Object?> get props => [email];
}

// Bắn event này khi đăng xuất
class AuthLogoutRequested extends AuthEvent {}