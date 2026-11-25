import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/data/local_database.dart';
import '../../core/models/mesh_message.dart';
import '../home/home_screen.dart';

class MeshScreen extends ConsumerStatefulWidget {
  const MeshScreen({super.key});
  @override
  ConsumerState<MeshScreen> createState() => _MeshScreenState();
}

class _MeshScreenState extends ConsumerState<MeshScreen> {
  final _name = TextEditingController(text: 'ResQMesh user');
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() { _name.dispose(); _message.dispose(); super.dispose(); }

  Future<void> _saveIncoming(String endpoint, Map<String, dynamic> data) async {
    final msg = MeshMessage(
      id: data['id']?.toString() ?? const Uuid().v4(),
      sender: data['sender']?.toString() ?? 'Nearby device',
      body: data['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      kind: data['kind']?.toString() ?? 'message',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
    await LocalDatabase.instance.save(msg);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message received and saved offline.')));
  }

  @override
  Widget build(BuildContext context) {
    final mesh = ref.watch(nearbyProvider);
    mesh.onMessage = _saveIncoming;
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby mesh')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: const InputDecoration(
          labelText: 'Device display name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton.icon(
            onPressed: _busy ? null : () async {
              setState(() => _busy = true);
              mesh.setDeviceName(_name.text);
              await mesh.startAdvertising();
              if (mounted) setState(() => _busy = false);
            },
            icon: const Icon(Icons.wifi_tethering), label: const Text('Become visible'))),
          const SizedBox(width: 9),
          Expanded(child: OutlinedButton.icon(
            onPressed: _busy ? null : () async {
              setState(() => _busy = true);
              mesh.setDeviceName(_name.text);
              await mesh.startDiscovery();
              if (mounted) setState(() => _busy = false);
            },
            icon: const Icon(Icons.radar), label: const Text('Find devices'))),
        ]),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: mesh.stop,
          icon: const Icon(Icons.stop_circle_outlined), label: const Text('Stop discovery / advertising')),
        if (mesh.incomingEndpoint != null) Card(
          color: const Color(0xFFFFF3DD),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connection request from ${mesh.incomingName ?? "nearby device"}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                TextButton(onPressed: mesh.rejectIncoming, child: const Text('Reject')),
                FilledButton(onPressed: mesh.acceptIncoming, child: const Text('Accept connection')),
              ]),
            ],
          )),
        ),
        const SizedBox(height: 14),
        Text('Discovered devices (${mesh.peers.length})',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        if (mesh.peers.isEmpty) const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text('No devices found yet. Keep both phones nearby, enable Bluetooth and location, and start discovery on one phone and advertising on the other.',
            style: TextStyle(color: Colors.black54, height: 1.4))),
        ...mesh.peers.map((peer) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.smartphone)),
          title: Text(peer.name), subtitle: Text(peer.id, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: TextButton(onPressed: () => mesh.connect(peer), child: const Text('Connect')),
        ))),
        const SizedBox(height: 14),
        Text('Connected devices (${mesh.connected.length})',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ...mesh.connected.map((id) => Card(child: ListTile(
          leading: const Icon(Icons.link, color: Colors.green),
          title: Text(id, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(icon: const Icon(Icons.link_off), onPressed: () => mesh.disconnect(id)),
        ))),
        const SizedBox(height: 14),
        const Text('Send a message', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _message, maxLines: 3,
          decoration: const InputDecoration(hintText: 'Type an offline message…', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: mesh.connected.isEmpty ? null : () async {
            mesh.setDeviceName(_name.text);
            final body = _message.text.trim();
            if (body.isEmpty) return;
            final data = {
              'id': const Uuid().v4(), 'sender': _name.text.trim().isEmpty ? 'ResQMesh user' : _name.text.trim(),
              'body': body, 'createdAt': DateTime.now().toIso8601String(),
              'kind': 'message', 'latitude': null, 'longitude': null,
            };
            for (final id in mesh.connected) {
              await mesh.send(id, data);
            }
            await LocalDatabase.instance.save(MeshMessage(
              id: data['id'] as String, sender: data['sender'] as String,
              body: body, createdAt: DateTime.now(), kind: 'message',
              deliveryState: 'sent to connected peers',
            ));
            _message.clear();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message sent to connected peers.')));
          },
          icon: const Icon(Icons.send), label: const Text('Send to connected peers')),
        if (mesh.lastError != null) Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(mesh.lastError!, style: const TextStyle(color: Colors.red))),
      ]),
    );
  }
}
