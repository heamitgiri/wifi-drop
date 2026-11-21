import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/peer.dart';
import '../security/identity.dart';
import '../storage/storage_service.dart';
import 'peer_registry.dart';

class DiscoveryService {
  static final DiscoveryService _instance = DiscoveryService._internal();
  factory DiscoveryService() => _instance;
  DiscoveryService._internal();

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  static const int broadcastPort = 8766;
  static final InternetAddress multicastGroup = InternetAddress('239.255.255.250');

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    PeerRegistry().start();

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
        reuseAddress: true,
        reusePort: !Platform.isWindows,
      );
      _socket?.broadcastEnabled = true;

      try {
        _socket?.joinMulticast(multicastGroup);
      } catch (_) {}

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleDatagram(datagram);
          }
        }
      });

      // Send initial announcement immediately
      _sendAnnouncement();

      // Setup periodic broadcast
      _broadcastTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _sendAnnouncement(),
      );
    } catch (e) {
      // If port is in use or blocked, retry with fallback
      _socket?.close();
      _socket = null;
    }
  }

  void _sendAnnouncement() {
    if (_socket == null || !_isRunning) return;

    final myId = IdentityService().deviceId;
    final mySettings = StorageService().settings;
    final deviceType = (Platform.isAndroid || Platform.isIOS) ? 'phone' : 'laptop';

    final payload = json.encode({
      'proto': 'wifidrop_v1',
      'id': myId,
      'name': mySettings.deviceName,
      'type': deviceType,
      'port': mySettings.port,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    final data = utf8.encode(payload);

    try {
      // Send to broadcast address
      _socket?.send(data, InternetAddress('255.255.255.255'), broadcastPort);
      // Send to multicast group
      _socket?.send(data, multicastGroup, broadcastPort);
    } catch (_) {}
  }

  void _handleDatagram(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      final jsonMap = json.decode(text) as Map<String, dynamic>;

      if (jsonMap['proto'] != 'wifidrop_v1') return;

      final peerId = jsonMap['id'] as String;
      final myId = IdentityService().deviceId;

      // Ignore our own announcement
      if (peerId == myId) return;

      final peerName = jsonMap['name'] as String? ?? 'Nearby Peer';
      final peerTypeStr = jsonMap['type'] as String? ?? 'laptop';
      final peerPort = jsonMap['port'] as int? ?? 8765;
      final peerIp = datagram.address.address;

      final deviceType = peerTypeStr == 'phone' ? DeviceType.phone : DeviceType.laptop;

      PeerRegistry().registerOrUpdatePeer(
        id: peerId,
        name: peerName,
        deviceType: deviceType,
        ipAddress: peerIp,
        port: peerPort,
      );
    } catch (_) {}
  }

  void stop() {
    _isRunning = false;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
    PeerRegistry().stop();
  }
}
