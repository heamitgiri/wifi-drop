import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/peer.dart';

class PeerRegistry extends ChangeNotifier {
  static final PeerRegistry _instance = PeerRegistry._internal();
  factory PeerRegistry() => _instance;
  PeerRegistry._internal();

  final Map<String, Peer> _peers = {};
  Timer? _pruneTimer;

  List<Peer> get activePeers {
    final now = DateTime.now();
    return _peers.values
        .where((p) => now.difference(p.lastSeen).inSeconds <= 12)
        .toList();
  }

  int get count => activePeers.length;

  void start() {
    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pruneStalePeers());
  }

  void stop() {
    _pruneTimer?.cancel();
    _peers.clear();
    notifyListeners();
  }

  void registerOrUpdatePeer({
    required String id,
    required String name,
    required DeviceType deviceType,
    required String ipAddress,
    required int port,
  }) {
    final now = DateTime.now();
    final existing = _peers[id];

    if (existing == null) {
      // Deterministic color assignment based on peer ID hash
      final colorIndex = id.hashCode.abs() % 8;
      _peers[id] = Peer(
        id: id,
        name: name,
        deviceType: deviceType,
        ipAddress: ipAddress,
        port: port,
        lastSeen: now,
        colorIndex: colorIndex,
      );
      notifyListeners();
    } else {
      bool changed = false;
      if (existing.name != name ||
          existing.ipAddress != ipAddress ||
          existing.port != port ||
          existing.deviceType != deviceType) {
        changed = true;
      }
      _peers[id] = existing.copyWith(
        name: name,
        deviceType: deviceType,
        ipAddress: ipAddress,
        port: port,
        lastSeen: now,
      );
      if (changed) {
        notifyListeners();
      }
    }
  }

  void removePeer(String id) {
    if (_peers.remove(id) != null) {
      notifyListeners();
    }
  }

  void _pruneStalePeers() {
    final now = DateTime.now();
    bool removed = false;
    _peers.removeWhere((id, peer) {
      if (now.difference(peer.lastSeen).inSeconds > 14) {
        removed = true;
        return true;
      }
      return false;
    });
    if (removed) {
      notifyListeners();
    }
  }

  Peer? getPeer(String id) => _peers[id];
}
