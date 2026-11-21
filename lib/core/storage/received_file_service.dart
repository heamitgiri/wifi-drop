import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'storage_service.dart';

class ReceivedFileService {
  static final ReceivedFileService _instance = ReceivedFileService._internal();
  factory ReceivedFileService() => _instance;
  ReceivedFileService._internal();

  String sanitizeFileName(String rawName) {
    var normalized = rawName.replaceAll('\\', '/');
    var name = p.basename(normalized);
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00]'), '_').trim();
    while (name.startsWith('.')) {
      name = name.substring(1).trim();
    }
    if (name.isEmpty) name = 'unnamed_file';
    if (name.length > 120) {
      final ext = p.extension(name);
      final stem = p.basenameWithoutExtension(name);
      name = '${stem.substring(0, 120 - ext.length)}$ext';
    }
    return name;
  }

  String getSafeDestinationPath(String targetDir, String fileName) {
    final sanitized = sanitizeFileName(fileName);
    final ext = p.extension(sanitized);
    final base = p.basenameWithoutExtension(sanitized);

    var candidate = p.join(targetDir, sanitized);
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(targetDir, '$base ($counter)$ext');
      counter++;
    }
    return candidate;
  }

  File getTempFileForTransfer(String transferId) {
    final saveDir = StorageService().settings.saveLocation;
    return File(p.join(saveDir, '.wifidrop_temp_$transferId.part'));
  }

  Future<bool> verifyAndFinalizeFile({
    required File tempFile,
    required String targetPath,
    required String? expectedSha256,
  }) async {
    if (!await tempFile.exists()) return false;

    if (expectedSha256 != null && expectedSha256.isNotEmpty) {
      final digest = await sha256.bind(tempFile.openRead()).first;
      final computed = digest.toString().toLowerCase();
      if (computed != expectedSha256.toLowerCase()) {
        await tempFile.delete();
        return false;
      }
    }

    try {
      await tempFile.rename(targetPath);
      return true;
    } catch (_) {
      try {
        await tempFile.copy(targetPath);
        await tempFile.delete();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> cleanupTempFile(String transferId) async {
    try {
      final temp = getTempFileForTransfer(transferId);
      if (await temp.exists()) {
        await temp.delete();
      }
    } catch (_) {}
  }
}
