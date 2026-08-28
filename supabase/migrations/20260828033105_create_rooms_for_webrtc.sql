-- Stumble Brawl — signaling WebRTC via Supabase Realtime
-- Tabela `rooms` para troca de SDP offer/answer + ICE (non-trickle)
-- Usada por SupabaseSignalingManager (lib/src/net/supabase_signaling.dart)
-- Ver lib/supabase_options.dart docs

-- 1) Tabela
create table if not exists public.rooms (
  code text primary key check (char_length(code) = 6),
  host_id text,
  offer jsonb,
  answer jsonb,
  -- candidates opcional (trickle futuro) — array jsonb
  candidates jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.rooms is 'Salas WebRTC P2P — signaling offer/answer para flutter_webrtc';
comment on column public.rooms.code is 'Código 6 chars [A-Z2-9] sem O/0/I/1';
comment on column public.rooms.host_id is 'ID opcional do host (anon)';
comment on column public.rooms.offer is 'SDP offer {sdp, type} do host';
comment on column public.rooms.answer is 'SDP answer {sdp, type} do guest';
comment on column public.rooms.candidates is 'ICE candidates agregados (trickle futuro)';

-- updated_at trigger
create or replace function public.handle_rooms_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

drop trigger if exists rooms_updated_at on public.rooms;
create trigger rooms_updated_at
  before update on public.rooms
  for each row execute function public.handle_rooms_updated_at();

-- 2) RLS — lobby P2P é anônimo por código (sem auth)
-- Qualquer anon pode criar/join se souber o código
alter table public.rooms enable row level security;

drop policy if exists "rooms_anon_all" on public.rooms;
create policy "rooms_anon_all"
  on public.rooms for all
  to anon, authenticated
  using (true)
  with check (true);

-- Grants explícitos (necessário se Data API auto_expose = false)
grant all on table public.rooms to anon, authenticated, service_role;

-- 3) Índices
create index if not exists idx_rooms_created_at on public.rooms (created_at desc);

-- 4) Realtime — Postgres publication para Realtime
-- Supabase Realtime escuta via supabase_realtime publication
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end; $$;

do $$
begin
  alter publication supabase_realtime add table public.rooms;
exception when duplicate_object then null;
end $$;

-- replica identity full ajuda no payload do Realtime (opcional mas útil para UPDATE)
alter table public.rooms replica identity full;

-- 5) Cleanup — salas expiram após 2h (lobby temporário)
-- Cron opcional via pg_cron se habilitado; fallback: delete manual no app leaveRoom
-- Descomente se pg_cron estiver ativo:
-- select cron.schedule('cleanup-rooms', '0 * * * *', $$ delete from public.rooms where created_at < now() - interval '2 hours' $$);
