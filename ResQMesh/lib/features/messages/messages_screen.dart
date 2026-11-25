import 'package:flutter/material.dart';
import '../../core/data/local_database.dart';
import '../../core/models/mesh_message.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}
class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<MeshMessage>> _items;
  @override
  void initState() { super.initState(); _items = LocalDatabase.instance.all(); }
  Future<void> _reload() async {
    setState(() => _items = LocalDatabase.instance.all());
    await _items;
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Offline message history')),
    body: FutureBuilder<List<MeshMessage>>(
      future: _items,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        if (items.isEmpty) return const Center(child: Text('No saved messages yet.'));
        return RefreshIndicator(onRefresh: _reload, child: ListView.builder(
          padding: const EdgeInsets.all(12), itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSos = item.kind == 'SOS';
            return Card(child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isSos ? const Color(0xFFFFE5E5) : const Color(0xFFE7F0FF),
                child: Icon(isSos ? Icons.sos : Icons.chat,
                  color: isSos ? Colors.red : Colors.blue)),
              title: Text(item.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.body),
                if (item.latitude != null) Text(
                  'Location: ${item.latitude!.toStringAsFixed(5)}, ${item.longitude!.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11)),
                Text('${item.createdAt.toLocal()} • ${item.deliveryState}',
                  style: const TextStyle(fontSize: 10, color: Colors.black45)),
              ]),
            ));
          },
        ));
      },
    ),
  );
}
