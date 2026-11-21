import 'package:flutter/material.dart';
import '../../core/models/peer.dart';

class PeerNode extends StatefulWidget {
  final Peer peer;
  final VoidCallback onTap;

  const PeerNode({
    super.key,
    required this.peer,
    required this.onTap,
  });

  static const List<Color> palette = [
    Color(0xFF16C6DA), // Cyan
    Color(0xFFFFC300), // Yellow
    Color(0xFFA72BF4), // Violet
    Color(0xFFF026BE), // Magenta
    Color(0xFF15CF9E), // Emerald
    Color(0xFFF9783E), // Orange
    Color(0xFF6178F7), // Royal Blue
    Color(0xFFEE4473), // Coral
  ];

  @override
  State<PeerNode> createState() => _PeerNodeState();
}

class _PeerNodeState extends State<PeerNode> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = PeerNode.palette[widget.peer.colorIndex % PeerNode.palette.length];
    final isLaptop = widget.peer.deviceType == DeviceType.laptop;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular chip
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    if (_isHovered)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: _isHovered ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  isLaptop ? Icons.laptop_mac_rounded : Icons.smartphone_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 6),
              // Device Name
              Container(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  widget.peer.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(
                        color: Color(0xFF04489A),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
