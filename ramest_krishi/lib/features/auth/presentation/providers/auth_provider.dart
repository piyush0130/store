import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_local_ds.dart';
import '../../data/datasources/auth_remote_ds.dart';
import '../../../../core/network/supabase_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

// -- Providers for Data Sources & Repositories --
final flutterSecureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final localAuthProvider = Provider((ref) => LocalAuthentication());

final authLocalDataSourceProvider = Provider((ref) {
  return AuthLocalDataSource(
    ref.watch(flutterSecureStorageProvider),
    ref.watch(localAuthProvider),
  );
});

final authRemoteDataSourceProvider = Provider((ref) {
  return AuthRemoteDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    localDataSource: ref.watch(authLocalDataSourceProvider),
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// -- State Management --
enum AuthStatus { initial, unauthenticated, locked, authenticated }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState()) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    state = state.copyWith(isLoading: true);
    final user = await _repository.getCurrentUser();
    
    if (user != null) {
      // User exists in cache, but app is locked until PIN is verified
      state = state.copyWith(
        status: AuthStatus.locked,
        user: user,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  Future<void> loginOnline(String phone, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final user = await _repository.loginOnline(phone, password);
      
      // On fresh login, they are authenticated but still need to setup PIN
      // We route to PIN setup next
      state = state.copyWith(status: AuthStatus.authenticated, user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> verifyOfflinePin(String pin) async {
    final success = await _repository.verifyOfflinePin(pin);
    if (success) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
    return success;
  }
  
  Future<void> setupPin(String pin) async {
    await _repository.setupOfflinePin(pin);
  }

  Future<void> authenticateBiometric() async {
    final success = await _repository.authenticateBiometric();
    if (success) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
