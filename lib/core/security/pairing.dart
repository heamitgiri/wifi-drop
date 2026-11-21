import 'dart:math';

class PairingHelper {
  static String generateShortCode() {
    final rand = Random.secure();
    final num = rand.nextInt(900000) + 100000;
    return num.toString();
  }

  static String generateVerificationSas(String myId, String peerId) {
    final sorted = [myId, peerId]..sort();
    final combined = sorted.join(':');
    final hash = combined.hashCode.abs() % 1000000;
    return hash.toString().padLeft(6, '0');
  }
}
