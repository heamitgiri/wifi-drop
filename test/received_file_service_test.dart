import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_drop/core/storage/received_file_service.dart';

void main() {
  group('ReceivedFileService Tests', () {
    final service = ReceivedFileService();

    test('Sanitizes malicious path traversal and illegal chars', () {
      expect(service.sanitizeFileName('../../etc/passwd'), 'passwd');
      expect(service.sanitizeFileName('..\\..\\Windows\\System32\\cmd.exe'), 'cmd.exe');
      expect(service.sanitizeFileName('my:movie*name?.mp4'), 'my_movie_name_.mp4');
      expect(service.sanitizeFileName('....'), 'unnamed_file');
      expect(service.sanitizeFileName('valid_document.docx'), 'valid_document.docx');
    });

    test('Collision avoidance generates indexed names', () {
      final tmp = Directory.systemTemp.createTempSync('wifidrop_test_');
      try {
        final f1 = File('${tmp.path}/sample.txt')..writeAsStringSync('one');
        final candidate1 = service.getSafeDestinationPath(tmp.path, 'sample.txt');
        expect(candidate1.endsWith('sample (1).txt'), isTrue);

        File(candidate1).writeAsStringSync('two');
        final candidate2 = service.getSafeDestinationPath(tmp.path, 'sample.txt');
        expect(candidate2.endsWith('sample (2).txt'), isTrue);
      } finally {
        tmp.deleteSync(recursive: true);
      }
    });
  });
}
