import 'package:buzzify/models/user.dart';
import 'package:buzzify/services/api_auth_service.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';



class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  final ApiAuthService _apiAuthService;

  AuthBloc({required ApiAuthService apiAuthService}) 
    : _apiAuthService = apiAuthService,
      super(const AuthState.unknown()) {
        
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthNeedsVerification>(_onNeedsVerification);
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthState.authenticated(event.user!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  void _onNeedsVerification(AuthNeedsVerification event, Emitter<AuthState> emit) {
    emit(AuthState.needsVerification(event.email));
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _apiAuthService.deleteToken(); // Xóa token
    emit(const AuthState.unauthenticated()); // Chuyển state
  }
  
  // Cần thiết cho HydratedBloc
  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      return AuthState.fromJson(json);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Map<String, dynamic>? toJson(AuthState state) {
    return state.toJson();
  }
}