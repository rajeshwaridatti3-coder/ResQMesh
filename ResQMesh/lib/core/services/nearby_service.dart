import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoveredPeer {
  const DiscoveredPeer(this.id, this.name);
  final String id;
  final String name;
}

class NearbyService extends ChangeNotifier {
  static const serviceId = 'com.resqmesh.emergency';
  final Nearby _nearby = Nearby();
  final Map<String, DiscoveredPeer> _peers = {};
  final Set<String> _connected = {};
  String? _lastError;
  String? _incomingEndpoint;
  String? _incomingName;
  String _deviceName = 'ResQMesh device';

  List<DiscoveredPeer> get peers => _peers.values.toList();
  Set<String> get connected => Set.unmodifiable(_connected);
  String? get lastError => _lastError;
  String? get incomingEndpoint => _incomingEndpoint;
  String? get incomingName => _incomingName;

  void setDeviceName(String name) {
    if (name.trim().isNotEmpty) _deviceName = name.trim();
  }

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
    final denied = statuses.entries.where((e) => !e.value.isGranted).toList();
    if (denied.isNotEmpty) {
      _lastError = 'Grant nearby-device, Bluetooth and location permissions to continue.';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> startDiscovery() async {
    try {
      if (!await requestPermissions()) return;
      _lastError = null;
      await _nearby.startDiscovery(
        _deviceName, Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, foundServiceId) {
          if (foundServiceId == serviceId) {
            _peers[id] = DiscoveredPeer(id, name);
            notifyListeners();
          }
        },
        onEndpointLost: (id) {
          if (id != null) _peers.remove(id);
          notifyListeners();
        },
        serviceId: serviceId,
      );
    } catch (e) {
      _lastError = 'Discovery failed: $e';
      notifyListeners();
    }
  }

  Future<void> startAdvertising() async {
    try {
      if (!await requestPermissions()) return;
      _lastError = null;
      await _nearby.startAdvertising(
        _deviceName, Strategy.P2P_CLUSTER,
        onConnectionInitiated: (id, info) {
          _incomingEndpoint = id;
          _incomingName = info.endpointName;
          notifyListeners();
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) _connected.add(id);
          notifyListeners();
        },
        onDisconnected: (id) {
          _connected.remove(id);
          notifyListeners();
        },
        serviceId: serviceId,
      );
    } catch (e) {
      _lastError = 'Advertising failed: $e';
      notifyListeners();
    }
  }

  Future<void> connect(DiscoveredPeer peer) async {
    try {
      await _nearby.requestConnection(
        _deviceName, peer.id,
        onConnectionInitiated: (id, info) {
          _incomingEndpoint = id;
          _incomingName = info.endpointName;
          notifyListeners();
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) _connected.add(id);
          notifyListeners();
        },
        onDisconnected: (id) {
          _connected.remove(id);
          notifyListeners();
        },
      );
    } catch (e) {
      _lastError = 'Connection failed: $e';
      notifyListeners();
    }
  }

  Future<void> acceptIncoming() async {
    final id = _incomingEndpoint;
    if (id == null) return;
    await _nearby.acceptConnection(id, onPayLoadRecieved: (endpointId, payload) {
      if (payload.type == PayloadType.BYTES && payload.bytes != null) {
        try {
          final decoded = jsonDecode(utf8.decode(payload.bytes!));
          onMessage?.call(endpointId, Map<String, dynamic>.from(decoded));
        } catch (_) {
          _lastError = 'Received a message with an invalid format.';
        }
      }
    });
    _connected.add(id);
    _incomingEndpoint = null;
    _incomingName = null;
    notifyListeners();
  }

  Future<void> rejectIncoming() async {
    final id = _incomingEndpoint;
    if (id != null) await _nearby.rejectConnection(id);
    _incomingEndpoint = null;
    _incomingName = null;
    notifyListeners();
  }

  void Function(String endpointId, Map<String, dynamic> data)? onMessage;

  Future<void> send(String endpointId, Map<String, dynamic> data) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    await _nearby.sendBytesPayload(endpointId, bytes);
  }

  Future<void> stop() async {
    await _nearby.stopDiscovery();
    await _nearby.stopAdvertising();
  }

  Future<void> disconnect(String id) async {
    await _nearby.disconnectFromEndpoint(id);
    _connected.remove(id);
    notifyListeners();
  }
}
