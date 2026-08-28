import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_options.dart';

// Supabase signaling para WebRTC — 100% cross-platform (inclui linux/windows nativo)
// Tabela `rooms` precisa existir (ver lib/supabase_options.dart docs)
// Fallback in-memory se Supabase não configurado (placeholder URL)

class SupabaseSignalingManager {
  final SupabaseClient? _client;
  RealtimeChannel? _channel;
  String? _currentCode;

  SupabaseSignalingManager() : _client = _initClient();

  static SupabaseClient? _initClient() {
    try {
      if (supabaseUrl.contains('placeholder')) return null;
      // Supabase.initialize pode não ter sido chamado ainda (main.dart faz)
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isConfigured => _client != null && !supabaseUrl.contains('placeholder');

  // Fallback in-memory para testes sem Supabase
  final Map<String, Map<String, dynamic>> _memoryRooms = {};

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(now + i * 37) % chars.length]).join();
  }

  Future<String> createRoom() async {
    final code = _genCode();
    _currentCode = code;
    if (!isConfigured) {
      _memoryRooms[code] = {'code': code, 'offer': null, 'answer': null, 'candidates': []};
      return code;
    }
    try {
      await _client!.from('rooms').insert({'code': code, 'candidates': []});
      _subscribe(code);
      return code;
    } catch (e) {
      // fallback memory se RLS/tabela não existir
      _memoryRooms[code] = {'code': code, 'offer': null, 'answer': null, 'candidates': []};
      return code;
    }
  }

  Future<Map<String, dynamic>?> joinRoom(String code) async {
    _currentCode = code;
    if (!isConfigured) {
      return _memoryRooms[code];
    }
    try {
      final row = await _client!.from('rooms').select().eq('code', code).maybeSingle();
      if (row != null) _subscribe(code);
      return row ?? _memoryRooms[code];
    } catch (_) {
      return _memoryRooms[code];
    }
  }

  Future<void> updateOffer(String code, Map<String, dynamic> offer) async {
    if (!isConfigured) {
      _memoryRooms[code]?['offer'] = offer;
      return;
    }
    try {
      await _client!.from('rooms').update({'offer': offer}).eq('code', code);
    } catch (_) {
      _memoryRooms[code]?['offer'] = offer;
    }
  }

  Future<void> updateAnswer(String code, Map<String, dynamic> answer) async {
    if (!isConfigured) {
      _memoryRooms[code]?['answer'] = answer;
      return;
    }
    try {
      await _client!.from('rooms').update({'answer': answer}).eq('code', code);
    } catch (_) {
      _memoryRooms[code]?['answer'] = answer;
    }
  }

  Future<Map<String, dynamic>?> getRoom(String code) async {
    if (!isConfigured) return _memoryRooms[code];
    try {
      return await _client!.from('rooms').select().eq('code', code).maybeSingle();
    } catch (_) {
      return _memoryRooms[code];
    }
  }

  void _subscribe(String code) {
    if (!isConfigured) return;
    try {
      _channel?.unsubscribe();
      _channel = _client!.channel('room:$code')
        ..onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'rooms', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'code', value: code), callback: (payload) {})
        ..subscribe();
    } catch (_) {}
  }

  Stream<Map<String, dynamic>> watchRoom(String code) {
    if (!isConfigured) {
      return Stream.periodic(const Duration(milliseconds: 500), (_) => _memoryRooms[code] ?? {}).distinct();
    }
    final controller = StreamController<Map<String, dynamic>>();
    try {
      final channel = _client!.channel('room-watch:$code');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'rooms',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'code', value: code),
        callback: (payload) => controller.add(payload.newRecord),
      ).subscribe();
      getRoom(code).then((r) { if (r != null) controller.add(r); });
      controller.onCancel = () => channel.unsubscribe();
    } catch (_) {
      controller.addStream(Stream.periodic(const Duration(milliseconds: 800), (_) => _memoryRooms[code] ?? {}));
    }
    return controller.stream;
  }

  Future<void> leaveRoom() async {
    final code = _currentCode;
    if (code == null) return;
    _channel?.unsubscribe();
    _channel = null;
    if (!isConfigured) {
      _memoryRooms.remove(code);
      return;
    }
    try {
      await _client!.from('rooms').delete().eq('code', code);
    } catch (_) {}
    _currentCode = null;
  }

  void dispose() {
    _channel?.unsubscribe();
  }
}
