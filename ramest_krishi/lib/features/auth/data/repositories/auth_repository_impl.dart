import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_local_ds.dart';
import '../datasources/auth_remote_ds.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<UserEntity?> getCurrentUser() async {
    final cachedData = await localDataSource.getCachedUserProfile();
    if (cachedData != null) {
      return _mapToEntity(cachedData);
    }
    return null;
  }

  @override
  Future<UserEntity> loginOnline(String phone, String password) async {
    final profileData = await remoteDataSource.login(phone, password);
    await localDataSource.cacheUserProfile(profileData);
    return _mapToEntity(profileData);
  }

  @override
  Future<bool> verifyOfflinePin(String pin) async {
    return await localDataSource.verifyPin(pin);
  }

  @override
  Future<void> setupOfflinePin(String pin) async {
    await localDataSource.savePin(pin);
  }

  @override
  Future<bool> authenticateBiometric() async {
    return await localDataSource.authenticateBiometrics();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearCache();
  }

  UserEntity _mapToEntity(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'],
      fullName: json['full_name'],
      role: json['role'] ?? 'cashier',
      branchId: json['branch_id'],
      phone: json['phone'],
    );
  }
}
