import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/discovery/discovery_service.dart';
import '../../core/discovery/peer_registry.dart';
import '../../core/models/peer.dart';
import '../../core/network/connection_service.dart';
import '../../core/storage/storage_service.dart';
import '../receive/incoming_request.dart';
import '../send/send_sheet.dart';
import '../settings/settings_screen.dart';
import '../transfers/transfer_progress.dart';
import 'peer_node.dart';
import 'radar_painter.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Register incoming transfer handler to display consent dialog
    ConnectionService().onIncomingOffer = (offer) async {
      return await IncomingRequestDialog.show(context, offer);
    };
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: StorageService().settings.deviceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter friendly device name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await StorageService().updateDeviceName(controller.text);
              if (mounted) setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0785F8), // Hard UI Lock Canvas Color
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([PeerRegistry(), ConnectionService()]),
          builder: (context, _) {
            final peers = PeerRegistry().activePeers;
            final transfers = ConnectionService().activeTransfersList;
            final pendingCount = transfers.where((t) => t.status == TransferStatus.transferring).length;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final radarSize = min(
                  constraints.maxWidth * (isWide ? 0.55 : 0.88),
                  constraints.maxHeight * 0.58,
                ).clamp(280.0, 560.0);

                return Column(
                  children: [
                    // Top App Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.wifi_tethering_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'WiFi Drop',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Transfers shortcut button with badge
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.sync_alt_rounded, color: Colors.white),
                                    tooltip: 'Transfers',
                                    onPressed: () => TransferProgressSheet.show(context),
                                  ),
                                  if (pendingCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$pendingCount',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                                tooltip: 'Settings',
                                onPressed: () => SettingsScreen.show(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Hero Titles
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Text(
                            'Searching Devices',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Quickly scan nearby WiFi Drop devices and share files.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFD9EEFF).withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Central Blue Radar Field
                    Center(
                      child: SizedBox(
                        width: radarSize,
                        height: radarSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Concentric Radar Rings Painter
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) => CustomPaint(
                                size: Size(radarSize, radarSize),
                                painter: RadarPainter(
                                  pulseAnimation: _animController.value,
                                ),
                              ),
                            ),

                            // Center Self Device Node
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0588F7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.laptop_chromebook_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  StorageService().settings.deviceName,
                                  style: const TextStyle(
                                    color: Color(0xFFE9F9FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(color: Color(0xFF0565C8), blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Discovered Peers scattered on the concentric rings
                            ...peers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final peer = entry.value;

                              // Deterministic placement on rings
                              final angle = ((index * 137.508 + 225) * pi / 180.0);
                              final radiusFraction = peers.length <= 4
                                  ? (index % 2 == 0 ? 0.38 : 0.44)
                                  : 0.42;

                              final distance = radarSize * radiusFraction;
                              final dx = (radarSize / 2) + distance * cos(angle) - 35;
                              final dy = (radarSize / 2) + distance * sin(angle) - 35;

                              return Positioned(
                                left: dx,
                                top: dy,
                                child: PeerNode(
                                  peer: peer,
                                  onTap: () => SendSheet.show(context, peer),
                                ),
                              );
                            }),

                            // Empty state hint
                            if (peers.isEmpty)
                              Positioned(
                                bottom: 18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'Waiting for other devices to open WiFi Drop…',
                                    style: TextStyle(
                                      color: Color(0xFFD9EEFF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Lower Scanning Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RotationTransition(
                          turns: _animController,
                          child: const Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          peers.isNotEmpty
                              ? '${peers.length} device${peers.length == 1 ? '' : 's'} available on this Wi-Fi'
                              : 'Searching for nearby devices on your Wi-Fi…',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bottom "My Device: [Name]" Pill
                    GestureDetector(
                      onTap: _showEditNameDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0071E5), // Spec Deep Blue Pill
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'My Device: ',
                              style: TextStyle(
                                color: Color(0xFFD9EEFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              StorageService().settings.deviceName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.edit_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
