import 'dart:async';
// Stub WebRTC P2P — Fase 3
// TODO Fase 3: implementar com flutter_webrtc + Firebase signaling
// Interface para não quebrar build até adicionar deps.
// Docs: https://pub.dev/packages/flutter_webrtc, https://firebase.google.com/docs/firestore

abstract class WebRTCManager {
  Future<void> createRoom(String roomCode);
  Future<void> joinRoom(String roomCode);
  Future<void> sendInput(Map<String, dynamic> input);
  Stream<Map<String, dynamic>> get onMessage;
  Future<void> dispose();
}

class InMemoryWebRTCManager implements WebRTCManager {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  @override
  Stream<Map<String, dynamic>> get onMessage => _controller.stream;
  @override
  Future<void> createRoom(String roomCode) async {}
  @override
  Future<void> joinRoom(String roomCode) async {}
  @override
  Future<void> sendInput(Map<String, dynamic> input) async => _controller.add(input);
  @override
  Future<void> dispose() async => _controller.close();
}
