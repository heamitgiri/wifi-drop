import 'package:flutter/material.dart';
import 'app.dart';
import 'core/discovery/discovery_service.dart';
import 'core/network/connection_service.dart';
import 'core/security/identity.dart';
import 'core/security/trust_store.dart';
import 'core/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage & identity services
  await StorageService().init();
  await IdentityService().init();
  await TrustStore().init();

  // Start network services
  await ConnectionService().startServer(StorageService().settings.port);
  await DiscoveryService().start();

  runApp(const WiFiDropApp());
}
