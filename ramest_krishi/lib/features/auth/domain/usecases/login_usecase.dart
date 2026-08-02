import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> execute(String phone, String password) async {
    return await repository.loginOnline(phone, password);
  }
}
