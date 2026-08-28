// Supabase config — substitua pelos valores do seu projeto
// Crie em https://supabase.com/dashboard → New Project → Settings → API
// Depois: flutter pub add supabase_flutter e inicialize em main.dart
// Este placeholder permite build sem credenciais (online lobby ficará em modo stub)

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://placeholder.supabase.co');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'placeholder-anon-key');

// Instruções:
// 1) Crie projeto supabase.com (region sa-east-1 recomendado)
// 2) SQL Editor → crie tabela:
//
//    create table rooms (
//      code text primary key,
//      host_id text,
//      offer jsonb,
//      answer jsonb,
//      candidates jsonb,
//      created_at timestamptz default now()
//    );
//    alter table rooms enable row level security;
//    create policy "open" on rooms for all using (true) with check (true);
//    -- Database → Publications → enable Realtime para `rooms`
//
// 3) Defina env ou edite este arquivo:
//    flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
//    ou edite diretamente as consts acima.
//
// 4) Teste: Lobby → Criar Sala → código 6 chars → 2 devices Join
