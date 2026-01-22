
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();

  /// Hashes a password using SHA-256 with a salt
  static String hashPassword(String password) {
    // In a real production app, use a unique salt per user stored in a DB
    const salt = "ludo_elite_secure_salt_2024"; 
    var bytes = utf8.encode(password + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Securely saves sensitive data
  static Future<void> saveSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Securely reads sensitive data
  static Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  /// Deletes secure data
  static Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }

  /// Sanitizes input strings to prevent basic injection/XSS (mostly relevant for web)
  static String sanitize(String input) {
    return input.replaceAll(RegExp(r'[<>&"|]'), '');
  }
}
