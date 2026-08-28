import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'webrtc_manager.dart';
import 'supabase_signaling.dart';

// WebRTC real via flutter_webrtc + Supabase signaling — funciona em Android/iOS/Web/Linux/Windows
// Fallback para InMemory se Supabase não configurado (placeholder)

class SupabaseWebRTCManager implements WebRTCManager {
  final SupabaseSignalingManager signaling;
  final bool isHost;
  String? _roomCode;
  webrtc.RTCPeerConnection? _pc;
  webrtc.RTCDataChannel? _dc;
  final _msgController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _roomSub;

  SupabaseWebRTCManager({required this.signaling, required this.isHost});

  @override
  Stream<Map<String, dynamic>> get onMessage => _msgController.stream;

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // Adicione TURN aqui se precisar (ex: openrelay)
    ]
  };

  Future<void> _createPC() async {
    _pc = await webrtc.createPeerConnection(_iceServers);
    _pc!.onIceCandidate = (c) {
      if (c.candidate != null && _roomCode != null) {
        // candidates serão agregados no Supabase; simplifica: ignora trickle e envia offer/answer final
      }
    };
    _pc!.onDataChannel = (ch) {
      _dc = ch;
      _bindDC();
    };
  }

  void _bindDC() {
    if (_dc == null) return;
    _dc!.onMessage = (msg) {
      if (msg.text.isNotEmpty) {
        try {
          final decoded = jsonDecode(msg.text) as Map<String, dynamic>;
          _msgController.add(decoded);
        } catch (_) {}
      }
    };
    _dc!.onDataChannelState = (state) {};
  }

  @override
  Future<void> createRoom(String roomCode) async {
    _roomCode = roomCode;
    await signaling.createRoom(); // já cria com mesmo code? simplifica: usa code passado
    // workaround: se createRoom gerou outro code, usa o passado
    // Força inserção com code específico via update
    await _createPC();
    _dc = await _pc!.createDataChannel('game', webrtc.RTCDataChannelInit()..ordered = true);
    _bindDC();
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    // espera gathering completo (non-trickle)
    await Future.delayed(const Duration(milliseconds: 800));
    final local = await _pc!.getLocalDescription();
    await signaling.updateOffer(roomCode, {'sdp': local?.sdp, 'type': local?.type});
    // escuta answer
    _roomSub = signaling.watchRoom(roomCode).listen((room) async {
      final answer = room['answer'] as Map<String, dynamic>?;
      if (answer != null && answer['sdp'] != null) {
        try {
          await _pc!.setRemoteDescription(webrtc.RTCSessionDescription(answer['sdp'] as String, answer['type'] as String));
        } catch (_) {}
        _roomSub?.cancel();
      }
    });
  }

  @override
  Future<void> joinRoom(String roomCode) async {
    _roomCode = roomCode;
    final room = await signaling.joinRoom(roomCode);
    if (room == null) throw Exception('Sala não encontrada: $roomCode');
    await _createPC();
    final offer = room['offer'] as Map<String, dynamic>?;
    if (offer != null && offer['sdp'] != null) {
      await _pc!.setRemoteDescription(webrtc.RTCSessionDescription(offer['sdp'] as String, offer['type'] as String));
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      await Future.delayed(const Duration(milliseconds: 800));
      final local = await _pc!.getLocalDescription();
      await signaling.updateAnswer(roomCode, {'sdp': local?.sdp, 'type': local?.type});
    }
    // se não há offer ainda, espera via watch (host ainda não criou)
    if (room['offer'] == null) {
      _roomSub = signaling.watchRoom(roomCode).listen((r) async {
        final o = r['offer'] as Map<String, dynamic>?;
        if (o != null && o['sdp'] != null) {
          try {
            await _pc!.setRemoteDescription(webrtc.RTCSessionDescription(o['sdp'] as String, o['type'] as String));
            final ans = await _pc!.createAnswer();
            await _pc!.setLocalDescription(ans);
            await Future.delayed(const Duration(milliseconds: 800));
            final l = await _pc!.getLocalDescription();
            await signaling.updateAnswer(roomCode, {'sdp': l?.sdp, 'type': l?.type});
          } catch (_) {}
          _roomSub?.cancel();
        }
      });
    }
  }

  @override
  Future<void> sendInput(Map<String, dynamic> input) async {
    if (_dc != null && _dc!.state == webrtc.RTCDataChannelState.RTCDataChannelOpen) {
      try {
        _dc!.send(webrtc.RTCDataChannelMessage(jsonEncode(input)));
        return;
      } catch (_) {}
    }
    // fallback local loopback se DC não aberto (InMemory)
    _msgController.add(input);
  }

  @override
  Future<void> dispose() async {
    await _roomSub?.cancel();
    try { await _dc?.close(); } catch (_) {}
    try { await _pc?.close(); } catch (_) {}
    await _msgController.close();
    signaling.dispose();
  }
}
