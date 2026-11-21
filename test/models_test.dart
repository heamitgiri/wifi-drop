import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_drop/core/models/peer.dart';
import 'package:wifi_drop/core/models/transfer.dart';
import 'package:wifi_drop/core/models/settings.dart';

void main() {
  group('Peer Model Tests', () {
    test('Peer serialization and deserialization', () {
      final now = DateTime.now();
      final peer = Peer(
        id: 'device-abc',
        name: 'Arun Laptop',
        deviceType: DeviceType.laptop,
        ipAddress: '192.168.1.100',
        port: 8765,
        lastSeen: now,
        colorIndex: 2,
      );

      final json = peer.toJson();
      expect(json['id'], 'device-abc');
      expect(json['name'], 'Arun Laptop');
      expect(json['type'], 'laptop');
      expect(json['ip'], '192.168.1.100');
      expect(json['port'], 8765);
      expect(json['color_index'], 2);

      final fromJson = Peer.fromJson(json);
      expect(fromJson.id, peer.id);
      expect(fromJson.name, peer.name);
      expect(fromJson.deviceType, peer.deviceType);
      expect(fromJson.ipAddress, peer.ipAddress);
      expect(fromJson.port, peer.port);
      expect(fromJson.colorIndex, peer.colorIndex);
    });

    test('Peer online status with TTL', () {
      final active = Peer(
        id: 'active',
        name: 'Active',
        deviceType: DeviceType.phone,
        ipAddress: '127.0.0.1',
        port: 8765,
        lastSeen: DateTime.now(),
        colorIndex: 0,
      );
      expect(active.isOnline, isTrue);

      final expired = Peer(
        id: 'expired',
        name: 'Expired',
        deviceType: DeviceType.phone,
        ipAddress: '127.0.0.1',
        port: 8765,
        lastSeen: DateTime.now().subtract(const Duration(seconds: 20)),
        colorIndex: 0,
      );
      expect(expired.isOnline, isFalse);
    });
  });

  group('Transfer Model Tests', () {
    test('Progress calculation and formatting', () {
      final transfer = Transfer(
        id: 't-1',
        peerId: 'p-1',
        peerName: 'Phone',
        fileName: 'presentation.pdf',
        fileSize: 10 * 1024 * 1024, // 10 MB
        isIncoming: true,
        bytesTransferred: 5 * 1024 * 1024, // 5 MB
      );

      expect(transfer.progress, closeTo(0.5, 0.01));
      expect(transfer.formattedSize, '10.0 MB');
      expect(transfer.formattedTransferred, '5.0 MB');
    });

    test('Format bytes helper', () {
      expect(Transfer.formatBytes(500), '500 B');
      expect(Transfer.formatBytes(2048), '2.0 KB');
      expect(Transfer.formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(Transfer.formatBytes(2 * 1024 * 1024 * 1024), '2.00 GB');
    });
  });

  group('Settings Model Tests', () {
    test('Default device name detection', () {
      final name = AppSettings.defaultDeviceName();
      expect(name.isNotEmpty, isTrue);
    });

    test('Settings serialization', () {
      final s = AppSettings(
        deviceName: 'Custom PC',
        saveLocation: 'C:\\Downloads\\WiFi Drop',
        askBeforeReceiving: true,
      );
      final json = s.toJson();
      expect(json['deviceName'], 'Custom PC');
      expect(json['saveLocation'], 'C:\\Downloads\\WiFi Drop');
      expect(json['askBeforeReceiving'], isTrue);

      final fromJson = AppSettings.fromJson(json);
      expect(fromJson.deviceName, 'Custom PC');
      expect(fromJson.saveLocation, 'C:\\Downloads\\WiFi Drop');
      expect(fromJson.askBeforeReceiving, isTrue);
    });
  });
}
