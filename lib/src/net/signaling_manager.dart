import 'dart:async';
// Stub Signaling — Firebase Firestore será usado em Fase 3
// TODO: implementar com cloud_firestore: rooms/{code} {offer, answer, candidates}

class SignalingManager {
  Future<String> createRoom() async {
    // gera código 6 letras
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(6, (_) => chars[(DateTime.now().millisecondsSinceEpoch % chars.length)]).join();
    return code;
  }
  Future<bool> joinRoom(String code) async => code.length == 6;
  Future<void> leaveRoom() async {}
}
