import 'dart:convert';

enum DeviceType { laptop, phone }

class Peer {
  final String id;
  final String name;
  final DeviceType deviceType;
  final String ipAddress;
  final int port;
  final DateTime lastSeen;
  final int colorIndex;

  Peer({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.ipAddress,
    required this.port,
    required this.lastSeen,
    required this.colorIndex,
  });

  bool get isOnline => DateTime.now().difference(lastSeen).inSeconds <= 12;

  Peer copyWith({
    String? id,
    String? name,
    DeviceType? deviceType,
    String? ipAddress,
    int? port,
    DateTime? lastSeen,
    int? colorIndex,
  }) {
    return Peer(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      lastSeen: lastSeen ?? this.lastSeen,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': deviceType == DeviceType.laptop ? 'laptop' : 'phone',
    'ip': ipAddress,
    'port': port,
    'last_seen': lastSeen.millisecondsSinceEpoch,
    'color_index': colorIndex,
  };

  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Nearby Device',
    deviceType: json['type'] == 'laptop' ? DeviceType.laptop : DeviceType.phone,
    ipAddress: json['ip'] as String? ?? '127.0.0.1',
    port: json['port'] as int? ?? 8765,
    lastSeen: json['last_seen'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['last_seen'] as int)
        : DateTime.now(),
    colorIndex: json['color_index'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Peer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
