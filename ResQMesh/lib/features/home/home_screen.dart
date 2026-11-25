import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/local_database.dart';
import '../../core/models/mesh_message.dart';
import '../../core/services/location_service.dart';
import '../../core/services/nearby_service.dart';
import '../mesh/mesh_screen.dart';
import '../messages/messages_screen.dart';
import '../sos/sos_screen.dart';

final nearbyProvider = ChangeNotifierProvider((ref) => NearbyService());

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _savedCount = 0;
  @override
  void initState() {
    super.initState();
    _refreshCount();
  }
  Future<void> _refreshCount() async {
    final items = await LocalDatabase.instance.all();
    if (mounted) setState(() => _savedCount = items.length);
  }

  @override
  Widget build(BuildContext context) {
    final nearby = ref.watch(nearbyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.hub_rounded, color: Color(0xFFFF7777)),
          SizedBox(width: 9),
          Text('ResQMesh', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [IconButton(
          tooltip: 'Message history',
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MessagesScreen())),
          icon: const Icon(Icons.history),
        )],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCount,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF17264A), Color(0xFF304D7D)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('WHEN NETWORKS FAIL,', style: TextStyle(color: Colors.white70,
                letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.bold)),
              SizedBox(height: 7),
              Text('Stay connected.\nStay safer.', style: TextStyle(
                color: Colors.white, fontSize: 27, height: 1.12, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Text('Send emergency messages to nearby ResQMesh devices without mobile data.',
                style: TextStyle(color: Colors.white70, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _stat('Nearby peers', '${nearby.peers.length}', Icons.radar)),
            const SizedBox(width: 10),
            Expanded(child: _stat('Saved records', '$_savedCount', Icons.offline_pin)),
          ]),
          const SizedBox(height: 18),
          _action(context, 'Emergency SOS', 'Create an alert with your current location',
            Icons.sos_rounded, const Color(0xFFFFE9E9), const Color(0xFFD92D3A),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen()))),
          const SizedBox(height: 12),
          _action(context, 'Nearby mesh', 'Discover, connect and exchange messages',
            Icons.bluetooth_searching_rounded, const Color(0xFFE8F0FF), const Color(0xFF3159A5),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshScreen()))),
          const SizedBox(height: 12),
          _action(context, 'Message history', 'Read messages saved on this device',
            Icons.chat_bubble_outline, const Color(0xFFE7F7F1), const Color(0xFF16845B),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()))),
          if (nearby.lastError != null) ...[
            const SizedBox(height: 14),
            Text(nearby.lastError!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          const Text('Important', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('ResQMesh is a peer-to-peer communication aid, not a replacement for emergency services. Nearby radio range, device compatibility and battery settings affect delivery.',
            style: TextStyle(color: Colors.black54, height: 1.45, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Card(
    child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
      Icon(icon, color: const Color(0xFF3159A5)), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ])),
    ])),
  );

  Widget _action(BuildContext context, String title, String subtitle, IconData icon,
      Color bg, Color fg, VoidCallback onTap) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      leading: CircleAvatar(backgroundColor: bg, foregroundColor: fg, child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
      onTap: onTap,
    ),
  );
}
