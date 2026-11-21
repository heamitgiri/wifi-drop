import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/transfer.dart';
import '../../core/network/connection_service.dart';

class TransferProgressSheet extends StatelessWidget {
  const TransferProgressSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const TransferProgressSheet(),
    );
  }

  void _openFileLocation(String filePath) {
    if (Platform.isWindows) {
      Process.run('explorer.exe', ['/select,', filePath]);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', filePath]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [File(filePath).parent.path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ConnectionService(),
      builder: (context, _) {
        final transfers = ConnectionService().activeTransfersList;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transfers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10253D),
                    ),
                  ),
                  Text(
                    '${transfers.length} items',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (transfers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No active or recent transfers',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: transfers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = transfers[index];
                      return _buildTransferTile(context, item);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransferTile(BuildContext context, Transfer item) {
    final isDone = item.status == TransferStatus.completed;
    final isFailed = item.status == TransferStatus.failed || item.status == TransferStatus.rejected;
    final isRunning = item.status == TransferStatus.transferring;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.isIncoming ? Icons.download_rounded : Icons.upload_rounded,
                size: 20,
                color: const Color(0xFF0785F8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRunning)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                  onPressed: () => ConnectionService().cancelTransfer(item.id),
                  tooltip: 'Cancel',
                )
              else if (isDone && item.filePath != null)
                TextButton(
                  onPressed: () => _openFileLocation(item.filePath!),
                  child: const Text('Open Folder', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isDone ? 1.0 : (isFailed ? 0.0 : item.progress),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFailed ? Colors.red : const Color(0xFF0785F8),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(item.progress * 100).toStringAsFixed(0)}% · ${item.formattedTransferred} of ${item.formattedSize}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              if (isRunning && item.speedBytesPerSec > 0)
                Text(
                  item.formattedSpeed,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF0785F8)),
                )
              else
                Text(
                  item.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDone ? Colors.green : (isFailed ? Colors.red : Colors.grey),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
