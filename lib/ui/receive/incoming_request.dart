import 'package:flutter/material.dart';
import '../../core/models/transfer.dart';
import '../../core/network/transfer_protocol.dart';

class IncomingRequestDialog extends StatelessWidget {
  final TransferOffer offer;
  final ValueChanged<bool> onDecision;

  const IncomingRequestDialog({
    super.key,
    required this.offer,
    required this.onDecision,
  });

  static Future<bool> show(BuildContext context, TransferOffer offer) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingRequestDialog(
        offer: offer,
        onDecision: (accepted) => Navigator.pop(context, accepted),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0785F8).withOpacity(0.12),
            child: const Icon(Icons.file_download_outlined, color: Color(0xFF0785F8)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Incoming File',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10253D),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: offer.senderName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10253D)),
              children: const [
                TextSpan(
                  text: ' wants to send you a file.',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCFE5FC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF0785F8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        Transfer.formatBytes(offer.fileSize),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      actions: [
        OutlinedButton(
          onPressed: () => onDecision(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () => onDecision(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0785F8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
