import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> loginOnline(String phone, String password);
  Future<bool> verifyOfflinePin(String pin);
  Future<void> setupOfflinePin(String pin);
  Future<bool> authenticateBiometric();
  Future<void> logout();
}
