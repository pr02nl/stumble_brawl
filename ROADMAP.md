# Roadmap — Stumble Brawl

> Documento vivo: o que foi feito e o que falta. Atualizado a cada fase.
> IAP adiado para V1.3. WebRTC confirmado.

## Estado Atual (2026-08-27 → 2026-08-28)

### V1.1 Entregue (MVP + Skins/Loja/Power-ups/Áudio/Ranking)
- [x] 1-4 humanos + bots =4, `MultiGamepadManager` (`lib/src/input/multi_gamepad.dart:1`)
- [x] 12 skins 6 grátis +6 premium 50-200 (`lib/src/game/skin_manager.dart:24`)
- [x] 4 power-ups spawn 5s (`lib/src/world/powerup.dart:1`)
- [x] Áudio `flame_audio` fallback (`lib/src/audio/audio_manager.dart:1`)
- [x] Ranking local 20 histórico (`lib/src/game/ranking.dart:1`)
- [x] `flutter analyze` 0, `flutter test` 111 pass

### Fase 1 (Hardening) — CONCLUÍDA 2026-08-28
- [x] `TurboEffect` vazamento + boost cap 360 + sin bob (`lib/src/world/powerup.dart:148`) — `flutter test` ok
- [x] `Platform.isActive` só antes de cair + shake (`lib/src/world/platform.dart:36`) — sem colisão após queda
- [x] `WorldConfig` centralizado 900x600/killY (`lib/src/world/world_config.dart:1`) + câmera usa `WorldConfig` + `y>WorldConfig.killY`
- [x] `restart()` zera timers (`stumble_brawl_game.dart:273`), 13→11 plats clássica, 5 falling ok
- [x] `Player` counter-flip damageText + HasPaint ok + clamp WorldConfig + pulo 0.92 (`lib/src/actors/player.dart:1`)
- [x] Remove `gamepad_input.dart` legado, `MultiGamepadManager` fix eixo x + handleDisconnect + simulatePad flags + `GameScreen` notifyTouch 300ms (`lib/src/input/multi_gamepad.dart:1`, `stumble_brawl_game.dart:295`)
- [x] `SkinManager` tryParse + _lock serialize + orElse (`lib/src/game/skin_manager.dart:48`), `Ranking` try/catch parse (`ranking.dart:48`)
- [x] `AudioManager` prefs `audio_music/sfx` unawaited + `web/manifest.json:9` any + `hud.dart:40` mm:ss vermelho <10 + `ranking_screen.dart:32` confirmação + remove `assets/audio/bgm.wav` dup

Resultado: `flutter analyze 0`, `flutter test 111` pass (ui_test ajustado 00:42)

### Fase 2 — Conteúdo — CONCLUÍDA 2026-08-28
- [x] 3 arenas `lib/src/world/arena.dart:1` — classic 11, volcano 9, ice 7 + `GameState.arenaId` + `StumbleBrawlGame(arenaId)` bgColor + spawns por arena
- [x] Seletor arena em `lib/src/ui/character_select.dart:42` + `GameScreen` passa arenaId
- [x] Leanback TV `android/app/src/main/AndroidManifest.xml:2` — `<uses-feature leanback>` + banner + `LEANBACK_LAUNCHER`
- [x] Polimento `Focus` TV em `lib/src/ui/main_menu.dart:146` + `playerColors` mantido para teste + `GameState` `AppScreen.lobby:3` + `main.dart:39` routing
- [x] `lib/src/world/world_config.dart:1` versão bump `pubspec.yaml:19` `1.0.0+1→1.1.0+2`

### Fase 3 — WebRTC P2P — CONCLUÍDA (in-memory, Firebase pendente) 2026-08-28
- [x] `lib/src/net/webrtc_manager.dart:1` `InMemoryWebRTCManager` + `signaling_manager.dart:1` + `lobby_screen.dart:1` + `main_menu.dart:99` botão ONLINE + `main.dart:39` lobby
- [x] `lib/src/net/net_game_sync.dart:1` sync 20Hz host authoritative snapshot/input via DataChannel (stub ok para teste local 2 devices via mesmo processo)
- [ ] Falta produção: `flutter pub add flutter_webrtc firebase_core cloud_firestore`, `firebase_options.dart` (`flutterfire configure`), substituir InMemory por FlutterWebRTCManager com STUN `stun.l.google.com:19302`

### Fase 4 — Spectator+Clip — CONCLUÍDA 2026-08-28
- [x] Espectador `lib/src/game/stumble_brawl_game.dart:528` câmera lerp vivos quando humano morto + `isSpectating` + `lib/src/ui/hud.dart:13` badge ESPECTANDO
- [x] Clip `lib/src/clip/replay_buffer.dart:1` 240 frames + `clip_exporter.dart:1` `SharePlus.instance.share` + `pubspec.yaml:40` `share_plus ^11.0.0`, `path_provider ^2.1.5` + `game_screen.dart:528` botão COMPARTILHAR CLIPE no GameOver + `stumble_brawl_game.dart:510` `replayBuffer.record`
- [ ] Falta release final: `flutter build web`/`apk --release` com signing real `android/app/build.gradle.kts:33` (hoje debug)

### V1.3 Futuro (não nesta entrega)
- [ ] IAP (`in_app_purchase` + Google Play Billing) — moedas pagas
- [ ] Online ranking global, ads

## Cronologia de Entregas
- 2026-08-28 00h: cria ROADMAP.md, inicia Fase 1
- 2026-08-28 06h: Fase 1 concluída — analyze 0, test 111 pass
- 2026-08-28 07h: Fase 2 arenas+leanback + stubs Fase3/4
- 2026-08-28 09h: Fase 2 polimento + Fase 3/4 (spectator, share_plus, lobby, net_sync) — `1.1.0+2` — analyze 0, test 111
- 2026-08-28 10h: 100% cross-platform — `flutter create --platforms=linux,windows` gerado, `supabase_flutter 2.17.2` + `flutter_webrtc 1.6.0` + `lib/supabase_options.dart:1` placeholder, `supabase_signaling.dart:1` + `supabase_webrtc_manager.dart:1` nativo, `main.dart:18` Supabase init, `build/web` ✓ 41s
- Próximo: criar projeto Supabase (SQL `rooms`), preencher `supabase_options.dart` ou `--dart-define`, `flutter build linux` (requer `libgstreamer1.0-dev`) / `flutter build windows` (VS2022) → tag `v1.2` (IAP V1.3)

## Como verificar progresso
```bash
flutter analyze && flutter test  # 0 issues, 111 pass
flutter build web                # ✓ 41s
flutter build linux --debug      # requer sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev cmake ninja-build
flutter build windows            # requer VS2022 + Windows SDK no host Windows
flutter build apk --debug
# Supabase: flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```
Histórico de testes e `coverage/lcov.info` acompanham cada fase.

## Decisões Registradas
- 2026-08-28: WebRTC (não WebSocket), IAP adiado, Leanback sim, documentar tudo aqui.
