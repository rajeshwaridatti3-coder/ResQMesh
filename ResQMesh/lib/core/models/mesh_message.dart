class MeshMessage {
  const MeshMessage({
    required this.id, required this.sender, required this.body,
    required this.createdAt, required this.kind, this.latitude, this.longitude,
    this.deliveryState = 'saved locally',
  });

  final String id;
  final String sender;
  final String body;
  final DateTime createdAt;
  final String kind;
  final double? latitude;
  final double? longitude;
  final String deliveryState;

  Map<String, Object?> toMap() => {
    'id': id, 'sender': sender, 'body': body,
    'created_at': createdAt.toIso8601String(), 'kind': kind,
    'latitude': latitude, 'longitude': longitude,
    'delivery_state': deliveryState,
  };

  factory MeshMessage.fromMap(Map<String, Object?> map) => MeshMessage(
    id: map['id'] as String,
    sender: map['sender'] as String,
    body: map['body'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    kind: map['kind'] as String,
    latitude: map['latitude'] as double?,
    longitude: map['longitude'] as double?,
    deliveryState: map['delivery_state'] as String? ?? 'saved locally',
  );
}
