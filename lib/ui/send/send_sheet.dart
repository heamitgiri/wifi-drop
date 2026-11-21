import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/models/peer.dart';
import '../../core/network/connection_service.dart';

class SendSheet extends StatelessWidget {
  final Peer peer;

  const SendSheet({super.key, required this.peer});

  static void show(BuildContext context, Peer peer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SendSheet(peer: peer),
    );
  }

  Future<void> _pickAndSendFiles(BuildContext context) async {
    Navigator.pop(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .where((file) => file.existsSync())
            .toList();

        for (final file in files) {
          // Send sequentially
          ConnectionService().sendFile(peer, file);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick files: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendFolder(BuildContext context) async {
    Navigator.pop(context);
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final dir = Directory(selectedDirectory);
        final entities = dir.listSync(recursive: true);
        final files = entities.whereType<File>().toList();

        for (final file in files) {
          ConnectionService().sendFile(peer, file);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLaptop = peer.deviceType == DeviceType.laptop;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0785F8).withOpacity(0.12),
                child: Icon(
                  isLaptop ? Icons.laptop_mac_rounded : Icons.smartphone_rounded,
                  color: const Color(0xFF0785F8),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10253D),
                      ),
                    ),
                    Text(
                      '${peer.ipAddress} · Ready to receive',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickAndSendFiles(context),
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Send Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0785F8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _pickAndSendFolder(context),
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Send Folder'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0785F8),
                side: const BorderSide(color: Color(0xFF0785F8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
