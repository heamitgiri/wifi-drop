import 'dart:convert';
import 'dart:io';

class AppSettings {
  String deviceName;
  String saveLocation;
  bool askBeforeReceiving;
  int port;
  int discoveryPort;

  AppSettings({
    required this.deviceName,
    required this.saveLocation,
    this.askBeforeReceiving = true,
    this.port = 8765,
    this.discoveryPort = 8766,
  });

  Map<String, dynamic> toJson() => {
    'deviceName': deviceName,
    'saveLocation': saveLocation,
    'askBeforeReceiving': askBeforeReceiving,
    'port': port,
    'discoveryPort': discoveryPort,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    deviceName: json['deviceName'] as String? ?? defaultDeviceName(),
    saveLocation: json['saveLocation'] as String? ?? '',
    askBeforeReceiving: json['askBeforeReceiving'] as bool? ?? true,
    port: json['port'] as int? ?? 8765,
    discoveryPort: json['discoveryPort'] as int? ?? 8766,
  );

  static String defaultDeviceName() {
    try {
      final host = Platform.localHostname;
      if (host.isNotEmpty) return host;
    } catch (_) {}
    if (Platform.isWindows) return 'Windows PC';
    if (Platform.isAndroid) return 'Android Phone';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isIOS) return 'iPhone';
    return 'WiFi Drop Peer';
  }
}
