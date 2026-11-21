import 'package:shared_preferences/shared_preferences.dart';

class TrustStore {
  static final TrustStore _instance = TrustStore._internal();
  factory TrustStore() => _instance;
  TrustStore._internal();

  static const String _keyTrustedPeers = 'wifi_drop_trusted_peers';
  final Set<String> _trustedPeerIds = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyTrustedPeers) ?? [];
    _trustedPeerIds.addAll(list);
  }

  bool isTrusted(String peerId) => _trustedPeerIds.contains(peerId);

  Future<void> addTrustedPeer(String peerId) async {
    _trustedPeerIds.add(peerId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyTrustedPeers, _trustedPeerIds.toList());
  }

  Future<void> removeTrustedPeer(String peerId) async {
    _trustedPeerIds.remove(peerId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyTrustedPeers, _trustedPeerIds.toList());
  }
}
