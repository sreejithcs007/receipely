import 'dart:convert';
import 'storage_service.dart';

class UserCacheService {
  final StorageService _storageService;
  static const String _userKey = 'cached_user_profile';

  UserCacheService(this._storageService);

  Future<void> cacheUser(Map<String, dynamic> userData) async {
    await _storageService.write(_userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getCachedUser() async {
    final cached = await _storageService.read(_userKey);
    if (cached == null) return null;
    try {
      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await _storageService.delete(_userKey);
  }
}
