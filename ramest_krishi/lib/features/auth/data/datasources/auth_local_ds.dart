import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  final LocalAuthentication localAuth;

  AuthLocalDataSource(this.secureStorage, this.localAuth);

  static const String _pinKey = 'user_offline_pin_hash';
  static const String _cachedUserKey = 'cached_user_profile';

  Future<void> savePin(String pin) async {
    final hash = _hashPin(pin);
    await secureStorage.write(key: _pinKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await secureStorage.read(key: _pinKey);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  Future<bool> authenticateBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await localAuth.isDeviceSupported();
      
      if (!canAuthenticate) return false;

      return await localAuth.authenticate(
        localizedReason: 'Please authenticate to login to Ramest Krishi',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> cacheUserProfile(Map<String, dynamic> userJson) async {
    await secureStorage.write(key: _cachedUserKey, value: jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    final data = await secureStorage.read(key: _cachedUserKey);
    if (data != null) return jsonDecode(data);
    return null;
  }

  Future<void> clearCache() async {
    await secureStorage.delete(key: _pinKey);
    await secureStorage.delete(key: _cachedUserKey);
  }

  String _hashPin(String pin) {
    // Simple SHA256 hash for local pin comparison
    var bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
