enum TransferStatus {
  pending,
  transferring,
  completed,
  rejected,
  cancelled,
  failed,
}

class Transfer {
  final String id;
  final String peerId;
  final String peerName;
  final String fileName;
  final int fileSize;
  final bool isIncoming;
  TransferStatus status;
  int bytesTransferred;
  double speedBytesPerSec;
  final String? checksum;
  String? errorMessage;
  String? filePath;
  final DateTime timestamp;

  Transfer({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.fileName,
    required this.fileSize,
    required this.isIncoming,
    this.status = TransferStatus.pending,
    this.bytesTransferred = 0,
    this.speedBytesPerSec = 0.0,
    this.checksum,
    this.errorMessage,
    this.filePath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get progress {
    if (fileSize <= 0) return 0.0;
    return (bytesTransferred / fileSize).clamp(0.0, 1.0);
  }

  String get formattedSize => formatBytes(fileSize);
  String get formattedTransferred => formatBytes(bytesTransferred);
  String get formattedSpeed => '${formatBytes(speedBytesPerSec.toInt())}/s';

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'peerId': peerId,
    'peerName': peerName,
    'fileName': fileName,
    'fileSize': fileSize,
    'isIncoming': isIncoming,
    'status': status.name,
    'bytesTransferred': bytesTransferred,
    'checksum': checksum,
    'errorMessage': errorMessage,
    'filePath': filePath,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory Transfer.fromJson(Map<String, dynamic> json) => Transfer(
    id: json['id'] as String,
    peerId: json['peerId'] as String,
    peerName: json['peerName'] as String,
    fileName: json['fileName'] as String,
    fileSize: json['fileSize'] as int,
    isIncoming: json['isIncoming'] as bool,
    status: TransferStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TransferStatus.failed,
    ),
    bytesTransferred: json['bytesTransferred'] as int? ?? 0,
    checksum: json['checksum'] as String?,
    errorMessage: json['errorMessage'] as String?,
    filePath: json['filePath'] as String?,
    timestamp: json['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
        : null,
  );
}
