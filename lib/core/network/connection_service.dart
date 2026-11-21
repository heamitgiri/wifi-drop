import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/peer.dart';
import '../models/transfer.dart';
import '../security/identity.dart';
import '../storage/received_file_service.dart';
import '../storage/storage_service.dart';
import 'transfer_protocol.dart';

typedef IncomingOfferCallback = Future<bool> Function(TransferOffer offer);

class ConnectionService extends ChangeNotifier {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  HttpServer? _server;
  bool _isListening = false;
  bool get isListening => _isListening;

  IncomingOfferCallback? onIncomingOffer;

  final Map<String, Transfer> _activeTransfers = {};
  List<Transfer> get activeTransfersList => _activeTransfers.values.toList();

  final Map<String, Completer<bool>> _pendingDecisions = {};
  final Set<String> _cancelledTransfers = {};

  Future<void> startServer([int port = 8765]) async {
    if (_isListening) return;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } catch (_) {
      // Fallback to automatic ephemeral port if port 8765 is taken
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    }

    StorageService().settings.port = _server!.port;
    await StorageService().saveSettings();
    _isListening = true;

    _server!.listen(_handleHttpRequest);
  }

  void _handleHttpRequest(HttpRequest request) async {
    // Add CORS headers for any diagnostic queries
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, X-Transfer-Id');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    if (path == '/api/ping') {
      final res = {
        'status': 'online',
        'id': IdentityService().deviceId,
        'name': StorageService().settings.deviceName,
      };
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode(res));
      await request.response.close();
      return;
    }

    if (path == '/api/transfer/offer' && request.method == 'POST') {
      await _handleOfferRequest(request);
      return;
    }

    if (path == '/api/transfer/stream' && request.method == 'POST') {
      await _handleStreamRequest(request);
      return;
    }

    if (path == '/api/transfer/cancel' && request.method == 'POST') {
      await _handleCancelRequest(request);
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> _handleOfferRequest(HttpRequest request) async {
    try {
      final body = await utf8.decodeStream(request);
      final jsonMap = json.decode(body) as Map<String, dynamic>;
      final offer = TransferOffer.fromJson(jsonMap);

      bool accept = false;
      if (!StorageService().settings.askBeforeReceiving) {
        accept = true;
      } else if (onIncomingOffer != null) {
        accept = await onIncomingOffer!(offer);
      }

      if (accept) {
        final transfer = Transfer(
          id: offer.transferId,
          peerId: offer.senderId,
          peerName: offer.senderName,
          fileName: offer.fileName,
          fileSize: offer.fileSize,
          isIncoming: true,
          status: TransferStatus.transferring,
          checksum: offer.sha256,
        );
        _activeTransfers[offer.transferId] = transfer;
        notifyListeners();
      }

      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode(TransferDecision(
        transferId: offer.transferId,
        accepted: accept,
      ).toJson()));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
    }
  }

  Future<void> _handleStreamRequest(HttpRequest request) async {
    final transferId = request.headers.value('X-Transfer-Id') ?? '';
    final transfer = _activeTransfers[transferId];

    if (transfer == null || _cancelledTransfers.contains(transferId)) {
      request.response.statusCode = HttpStatus.gone;
      await request.response.close();
      return;
    }

    final tempFile = ReceivedFileService().getTempFileForTransfer(transferId);
    final sink = tempFile.openWrite();
    int receivedBytes = 0;
    final stopwatch = Stopwatch()..start();

    try {
      await for (final chunk in request) {
        if (_cancelledTransfers.contains(transferId)) {
          throw Exception('Cancelled by user');
        }
        sink.add(chunk);
        receivedBytes += chunk.length;
        transfer.bytesTransferred = receivedBytes;

        if (stopwatch.elapsedMilliseconds >= 300) {
          final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
          transfer.speedBytesPerSec = elapsedSec > 0 ? (receivedBytes / elapsedSec) : 0;
          notifyListeners();
        }
      }
      await sink.flush();
      await sink.close();

      // Finalize file
      final safePath = ReceivedFileService().getSafeDestinationPath(
        StorageService().settings.saveLocation,
        transfer.fileName,
      );

      final verified = await ReceivedFileService().verifyAndFinalizeFile(
        tempFile: tempFile,
        targetPath: safePath,
        expectedSha256: transfer.checksum,
      );

      if (verified) {
        transfer.status = TransferStatus.completed;
        transfer.filePath = safePath;
        transfer.bytesTransferred = transfer.fileSize;
      } else {
        transfer.status = TransferStatus.failed;
        transfer.errorMessage = 'Integrity verification failed';
      }

      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({'status': transfer.status.name, 'path': safePath}));
      await request.response.close();
    } catch (e) {
      await sink.close();
      await ReceivedFileService().cleanupTempFile(transferId);
      transfer.status = TransferStatus.failed;
      transfer.errorMessage = e.toString();
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    } finally {
      notifyListeners();
    }
  }

  Future<void> _handleCancelRequest(HttpRequest request) async {
    final body = await utf8.decodeStream(request);
    final jsonMap = json.decode(body) as Map<String, dynamic>;
    final transferId = jsonMap['transferId'] as String;

    _cancelledTransfers.add(transferId);
    final transfer = _activeTransfers[transferId];
    if (transfer != null) {
      transfer.status = TransferStatus.cancelled;
      await ReceivedFileService().cleanupTempFile(transferId);
      notifyListeners();
    }

    request.response.statusCode = HttpStatus.ok;
    await request.response.close();
  }

  /// Client: Send file to a target peer
  Future<void> sendFile(Peer peer, File file) async {
    final fileName = file.uri.pathSegments.last;
    final fileSize = await file.length();
    final transferId = '${DateTime.now().millisecondsSinceEpoch}_${IdentityService().deviceId}';

    final transfer = Transfer(
      id: transferId,
      peerId: peer.id,
      peerName: peer.name,
      fileName: fileName,
      fileSize: fileSize,
      isIncoming: false,
      status: TransferStatus.pending,
      filePath: file.path,
    );

    _activeTransfers[transferId] = transfer;
    notifyListeners();

    try {
      // 1. Calculate SHA-256 digest
      final digest = await sha256.bind(file.openRead()).first;
      final shaStr = digest.toString();

      // 2. Offer transfer
      final offer = TransferOffer(
        transferId: transferId,
        senderId: IdentityService().deviceId,
        senderName: StorageService().settings.deviceName,
        fileName: fileName,
        fileSize: fileSize,
        sha256: shaStr,
      );

      final offerUri = Uri.parse('http://${peer.ipAddress}:${peer.port}/api/transfer/offer');
      final offerRes = await http.post(
        offerUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(offer.toJson()),
      ).timeout(const Duration(seconds: 45));

      if (offerRes.statusCode != 200) {
        transfer.status = TransferStatus.failed;
        transfer.errorMessage = 'Connection refused by peer';
        notifyListeners();
        return;
      }

      final decisionMap = json.decode(offerRes.body);
      final accepted = decisionMap['accepted'] as bool? ?? false;

      if (!accepted) {
        transfer.status = TransferStatus.rejected;
        notifyListeners();
        return;
      }

      // 3. Stream data
      transfer.status = TransferStatus.transferring;
      notifyListeners();

      final streamUri = Uri.parse('http://${peer.ipAddress}:${peer.port}/api/transfer/stream');
      final request = http.StreamedRequest('POST', streamUri);
      request.headers['X-Transfer-Id'] = transferId;
      request.headers['Content-Length'] = fileSize.toString();

      int bytesSent = 0;
      final stopwatch = Stopwatch()..start();

      final fileStream = file.openRead();
      final streamSubscription = fileStream.listen(
        (chunk) {
          if (_cancelledTransfers.contains(transferId)) {
            request.sink.close();
            return;
          }
          request.sink.add(chunk);
          bytesSent += chunk.length;
          transfer.bytesTransferred = bytesSent;

          if (stopwatch.elapsedMilliseconds >= 300) {
            final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
            transfer.speedBytesPerSec = elapsedSec > 0 ? (bytesSent / elapsedSec) : 0;
            notifyListeners();
          }
        },
        onDone: () => request.sink.close(),
        onError: (e) => request.sink.addError(e),
        cancelOnError: true,
      );

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        transfer.status = TransferStatus.completed;
        transfer.bytesTransferred = fileSize;
      } else {
        transfer.status = TransferStatus.failed;
        transfer.errorMessage = 'Transfer aborted by receiver';
      }
    } catch (e) {
      transfer.status = TransferStatus.failed;
      transfer.errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void cancelTransfer(String transferId) {
    _cancelledTransfers.add(transferId);
    final transfer = _activeTransfers[transferId];
    if (transfer != null) {
      transfer.status = TransferStatus.cancelled;
      notifyListeners();
    }
  }

  void stop() {
    _isListening = false;
    _server?.close(force: true);
    _server = null;
    _activeTransfers.clear();
    _cancelledTransfers.clear();
  }
}
