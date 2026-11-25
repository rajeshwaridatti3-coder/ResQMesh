import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/data/local_database.dart';
import '../../core/models/mesh_message.dart';
import '../../core/services/location_service.dart';
import '../home/home_screen.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});
  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final _note = TextEditingController(text: 'I need help. Please check on me.');
  bool _sending = false;
  String _status = 'Your alert will be saved locally and sent to connected ResQMesh peers.';

  @override
  void dispose() { _note.dispose(); super.dispose(); }

  Future<void> _trigger() async {
    setState(() { _sending = true; _status = 'Getting location…'; });
    double? lat, lon;
    try {
      final position = await LocationService().currentPosition();
      lat = position?.latitude;
      lon = position?.longitude;
    } catch (_) {}
    final id = const Uuid().v4();
    final body = _note.text.trim().isEmpty ? 'Emergency. I need help.' : _note.text.trim();
    final data = {
      'id': id, 'sender': 'Emergency alert', 'body': body,
      'createdAt': DateTime.now().toIso8601String(), 'kind': 'SOS',
      'latitude': lat, 'longitude': lon,
    };
    await LocalDatabase.instance.save(MeshMessage(
      id: id, sender: 'Emergency alert', body: body,
      createdAt: DateTime.now(), kind: 'SOS', latitude: lat, longitude: lon,
      deliveryState: 'saved locally; sharing attempted with connected peers',
    ));
    final mesh = ref.read(nearbyProvider);
    var sent = 0;
    for (final peer in mesh.connected) {
      try { await mesh.send(peer, data); sent++; } catch (_) {}
    }
    if (mounted) setState(() {
      _sending = false;
      _status = lat == null
        ? 'SOS saved locally and shared with $sent connected peer(s). Location unavailable.'
        : 'SOS saved locally and shared with $sent connected peer(s). Location: ${lat.toStringAsFixed(5)}, ${lon!.toStringAsFixed(5)}.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Emergency SOS')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: const Color(0xFFFFE8E8),
          borderRadius: BorderRadius.circular(20)),
        child: const Column(children: [
          Icon(Icons.sos_rounded, color: Color(0xFFD92D3A), size: 58),
          SizedBox(height: 8),
          Text('Create an emergency alert', style: TextStyle(
            color: Color(0xFF9F1D2B), fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Your alert is stored on this phone and sent to currently connected peers.',
            textAlign: TextAlign.center, style: TextStyle(height: 1.4)),
        ]),
      ),
      const SizedBox(height: 18),
      TextField(controller: _note, maxLines: 4,
        decoration: const InputDecoration(labelText: 'Emergency message',
          border: OutlineInputBorder(), alignLabelWithHint: true)),
      const SizedBox(height: 14),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD92D3A),
          padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: _sending ? null : _trigger,
        icon: const Icon(Icons.warning_amber_rounded),
        label: Text(_sending ? 'Creating alert…' : 'CREATE AND SHARE SOS')),
      const SizedBox(height: 14),
      Text(_status, style: const TextStyle(height: 1.45, color: Colors.black54)),
      const SizedBox(height: 18),
      const Text('Safety note', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('This app does not automatically contact police, ambulance or other emergency services. If you are in immediate danger, use your local emergency number whenever possible.',
        style: TextStyle(color: Colors.black54, height: 1.45)),
    ]),
  );
}
