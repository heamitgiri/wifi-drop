import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/storage/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  late TextEditingController _nameController;
  late bool _askBeforeReceiving;
  late String _saveLocation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _storage.settings.deviceName);
    _askBeforeReceiving = _storage.settings.askBeforeReceiving;
    _saveLocation = _storage.settings.saveLocation;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changeFolder() async {
    final selected = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Received Files Destination',
      initialDirectory: _saveLocation,
    );
    if (selected != null && selected.isNotEmpty) {
      final success = await _storage.updateSaveLocation(selected);
      if (success) {
        setState(() => _saveLocation = selected);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected directory is not writable')),
        );
      }
    }
  }

  Future<void> _resetFolder() async {
    final def = await _storage.getDefaultSaveLocation();
    await _storage.updateSaveLocation(def.path);
    setState(() => _saveLocation = def.path);
  }

  void _openFolder() {
    if (Platform.isWindows) {
      Process.run('explorer.exe', [_saveLocation]);
    } else if (Platform.isMacOS) {
      Process.run('open', [_saveLocation]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [_saveLocation]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF10253D),
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('DEVICE IDENTITY'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Friendly Device Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. My Laptop',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _storage.updateDeviceName(_nameController.text);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Device name updated')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0785F8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Visible to other nearby WiFi Drop devices on the same Wi-Fi.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('STORAGE & SAVE LOCATION'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Received Files Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _saveLocation,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _changeFolder,
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('Change Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0785F8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
                      OutlinedButton.icon(
                        onPressed: _openFolder,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open Folder'),
                      ),
                    ],
                    TextButton(
                      onPressed: _resetFolder,
                      child: const Text('Reset to Default'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('SECURITY & PERMISSIONS'),
          _buildCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ask before receiving files', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Untrusted peers must request your permission before sending any file.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              value: _askBeforeReceiving,
              activeColor: const Color(0xFF0785F8),
              onChanged: (val) async {
                setState(() => _askBeforeReceiving = val);
                await _storage.setAskBeforeReceiving(val);
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('ABOUT'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WiFi Drop v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '100% Local Wi-Fi peer-to-peer file sharing. No cloud relay, no tracking, no external accounts.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
