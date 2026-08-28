// Supabase config — não commitar chaves reais em repo público
// Infra já configurada (tabela public.rooms + Realtime) — ver supabase/migrations
// Injeção via --dart-define (recomendado) ou env:
//   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
// Obtenha as chaves em https://supabase.com/dashboard → Settings → API
// Este placeholder mantém build sem credenciais (lobby cai para in-memory stub)

const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://placeholder.supabase.co',
);
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'placeholder-anon-key',
);

bool get isSupabaseConfigured =>
    !supabaseUrl.contains('placeholder') && !supabaseAnonKey.contains('placeholder');

// Instruções (infra já aplicada):
// 1) Migração supabase/migrations/20260828033105_create_rooms_for_webrtc.sql
//    cria public.rooms (code PK 6 chars, offer/answer/candidates jsonb, updated_at trigger,
//    RLS anon+authenticated using true, Realtime publication, grant anon/authenticated)
// 2) Teste: Lobby → Criar Sala → código 6 chars → 2 devices Join
//    (SupabaseSignalingManager + SupabaseWebRTCManager, fallback in-memory se não configurado)
