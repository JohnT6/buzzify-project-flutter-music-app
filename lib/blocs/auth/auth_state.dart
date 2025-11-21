part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, needsVerification }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? emailForVerification; // Lưu email để gửi sang trang OTP

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.emailForVerification,
  });
  
  // Trạng thái ban đầu
  const AuthState.unknown() : this();

  // Trạng thái đã đăng nhập
  const AuthState.authenticated(User user) 
    : this(status: AuthStatus.authenticated, user: user);
    
  // Trạng thái chưa đăng nhập
  const AuthState.unauthenticated() 
    : this(status: AuthStatus.unauthenticated);

  // Trạng thái chờ xác thực
  const AuthState.needsVerification(String email)
    : this(status: AuthStatus.needsVerification, emailForVerification: email);

  @override
  List<Object?> get props => [status, user, emailForVerification];
  
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? emailForVerification,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      emailForVerification: emailForVerification ?? this.emailForVerification,
    );
  }

  // Cần thiết cho HydratedBloc
  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      status: AuthStatus.values[json['status'] as int],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      emailForVerification: json['emailForVerification'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'user': user?.toJson(),
      'emailForVerification': emailForVerification,
    };
  }
}