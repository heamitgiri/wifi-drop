import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_drop/core/discovery/peer_registry.dart';
import 'package:wifi_drop/core/models/peer.dart';

void main() {
  group('PeerRegistry Tests', () {
    final registry = PeerRegistry();

    setUp(() {
      registry.stop();
      registry.start();
    });

    tearDown(() {
      registry.stop();
    });

    test('Registers and updates peer with stable color', () {
      registry.registerOrUpdatePeer(
        id: 'peer-1',
        name: 'Laptop 1',
        deviceType: DeviceType.laptop,
        ipAddress: '192.168.1.10',
        port: 8765,
      );

      expect(registry.count, 1);
      final p1 = registry.getPeer('peer-1');
      expect(p1, isNotNull);
      expect(p1!.name, 'Laptop 1');
      final originalColor = p1.colorIndex;

      // Update peer details
      registry.registerOrUpdatePeer(
        id: 'peer-1',
        name: 'Laptop 1 (Renamed)',
        deviceType: DeviceType.laptop,
        ipAddress: '192.168.1.10',
        port: 8765,
      );

      expect(registry.count, 1);
      final p1Updated = registry.getPeer('peer-1');
      expect(p1Updated!.name, 'Laptop 1 (Renamed)');
      expect(p1Updated.colorIndex, originalColor); // Color index is stable
    });

    test('Removes peer on demand', () {
      registry.registerOrUpdatePeer(
        id: 'peer-temp',
        name: 'Temp Peer',
        deviceType: DeviceType.phone,
        ipAddress: '192.168.1.20',
        port: 8765,
      );
      expect(registry.count, 1);

      registry.removePeer('peer-temp');
      expect(registry.count, 0);
    });
  });
}
