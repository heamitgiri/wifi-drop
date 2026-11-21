class TransferOffer {
  final String transferId;
  final String senderId;
  final String senderName;
  final String fileName;
  final int fileSize;
  final String? sha256;

  TransferOffer({
    required this.transferId,
    required this.senderId,
    required this.senderName,
    required this.fileName,
    required this.fileSize,
    this.sha256,
  });

  Map<String, dynamic> toJson() => {
    'transferId': transferId,
    'senderId': senderId,
    'senderName': senderName,
    'fileName': fileName,
    'fileSize': fileSize,
    'sha256': sha256,
  };

  factory TransferOffer.fromJson(Map<String, dynamic> json) => TransferOffer(
    transferId: json['transferId'] as String,
    senderId: json['senderId'] as String,
    senderName: json['senderName'] as String,
    fileName: json['fileName'] as String,
    fileSize: json['fileSize'] as int,
    sha256: json['sha256'] as String?,
  );
}

class TransferDecision {
  final String transferId;
  final bool accepted;
  final String? reason;

  TransferDecision({
    required this.transferId,
    required this.accepted,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'transferId': transferId,
    'accepted': accepted,
    'reason': reason,
  };

  factory TransferDecision.fromJson(Map<String, dynamic> json) => TransferDecision(
    transferId: json['transferId'] as String,
    accepted: json['accepted'] as bool,
    reason: json['reason'] as String?,
  );
}
