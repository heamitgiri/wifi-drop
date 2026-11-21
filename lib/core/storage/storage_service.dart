import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/settings.dart';
import '../models/transfer.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  AppSettings? _settings;
  AppSettings get settings => _settings ?? AppSettings(
    deviceName: AppSettings.defaultDeviceName(),
    saveLocation: '',
  );

  File? _settingsFile;
  File? _historyFile;

  Future<void> init() async {
    final appDir = await _getAppConfigDirectory();
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    _settingsFile = File(p.join(appDir.path, 'settings.json'));
    _historyFile = File(p.join(appDir.path, 'history.json'));

    if (await _settingsFile!.exists()) {
      try {
        final content = await _settingsFile!.readAsString();
        _settings = AppSettings.fromJson(json.decode(content));
      } catch (_) {
        _settings = null;
      }
    }

    if (_settings == null || _settings!.saveLocation.isEmpty) {
      final defaultDir = await getDefaultSaveLocation();
      if (!await defaultDir.exists()) {
        await defaultDir.create(recursive: true);
      }
      _settings = AppSettings(
        deviceName: _settings?.deviceName ?? AppSettings.defaultDeviceName(),
        saveLocation: defaultDir.path,
        askBeforeReceiving: _settings?.askBeforeReceiving ?? true,
      );
      await saveSettings();
    }
  }

  Future<Directory> _getAppConfigDirectory() async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        return Directory(p.join(localAppData, 'WiFiDrop'));
      }
    }
    final docDir = await getApplicationSupportDirectory();
    return Directory(p.join(docDir.path, 'WiFiDrop'));
  }

  Future<Directory> getDefaultSaveLocation() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        return Directory(p.join(userProfile, 'Downloads', 'WiFi Drop'));
      }
    }
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return Directory(p.join(downloadsDir.path, 'WiFi Drop'));
      }
    } catch (_) {}

    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDocDir.path, 'WiFi Drop'));
  }

  Future<void> saveSettings() async {
    if (_settingsFile == null || _settings == null) return;
    await _settingsFile!.writeAsString(json.encode(_settings!.toJson()));
  }

  Future<void> updateDeviceName(String newName) async {
    if (newName.trim().isEmpty) return;
    settings.deviceName = newName.trim();
    await saveSettings();
  }

  Future<bool> updateSaveLocation(String newPath) async {
    final dir = Directory(newPath);
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // Test writability
      final testFile = File(p.join(dir.path, '.test_write_${DateTime.now().millisecondsSinceEpoch}'));
      await testFile.writeAsString('test');
      await testFile.delete();

      settings.saveLocation = dir.path;
      await saveSettings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setAskBeforeReceiving(bool value) async {
    settings.askBeforeReceiving = value;
    await saveSettings();
  }

  Future<List<Transfer>> loadHistory() async {
    if (_historyFile == null || !await _historyFile!.exists()) return [];
    try {
      final content = await _historyFile!.readAsString();
      final List<dynamic> list = json.decode(content);
      return list.map((item) => Transfer.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<Transfer> history) async {
    if (_historyFile == null) return;
    try {
      final items = history.take(100).map((t) => t.toJson()).toList();
      await _historyFile!.writeAsString(json.encode(items));
    } catch (_) {}
  }
}
