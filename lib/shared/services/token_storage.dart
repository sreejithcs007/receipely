import 'storage_service.dart';

class TokenStorage {
  final StorageService _storageService;
  static const String _tokenKey = 'auth_token';

  TokenStorage(this._storageService);

  Future<void> saveToken(String token) async {
    await _storageService.write(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return await _storageService.read(_tokenKey);
  }

  Future<void> deleteToken() async {
    await _storageService.delete(_tokenKey);
  }
}
