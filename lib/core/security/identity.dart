import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdentityService {
  static final IdentityService _instance = IdentityService._internal();
  factory IdentityService() => _instance;
  IdentityService._internal();

  static const String _keyDeviceId = 'wifi_drop_device_id';
  static const String _keyDeviceSecret = 'wifi_drop_device_secret';

  String? _deviceId;
  String? _deviceSecret;

  String get deviceId => _deviceId ?? 'unknown';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_keyDeviceId);
    _deviceSecret = prefs.getString(_keyDeviceSecret);

    if (_deviceId == null || _deviceSecret == null) {
      final rand = Random.secure();
      final idBytes = List<int>.generate(16, (_) => rand.nextInt(256));
      final secretBytes = List<int>.generate(32, (_) => rand.nextInt(256));

      _deviceId = sha256.convert(idBytes).toString().substring(0, 16);
      _deviceSecret = base64Url.encode(secretBytes);

      await prefs.setString(_keyDeviceId, _deviceId!);
      await prefs.setString(_keyDeviceSecret, _deviceSecret!);
    }
  }

  String signMessage(String message) {
    if (_deviceSecret == null) return '';
    final hmacSha = Hmac(sha256, utf8.encode(_deviceSecret!));
    return hmacSha.convert(utf8.encode(message)).toString();
  }
}
