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

### Fase 2 — Conteúdo — PARCIALMENTE CONCLUÍDA 2026-08-28
- [x] 3 arenas `lib/src/world/arena.dart:1` — classic 11, volcano 9, ice 7 + `GameState.arenaId` + `StumbleBrawlGame(arenaId)` bgColor + spawns por arena
- [x] Seletor arena em `lib/src/ui/character_select.dart:1` + `GameScreen` passa arenaId
- [x] Leanback TV `android/app/src/main/AndroidManifest.xml:2` — `<uses-feature leanback>` + banner + `LEANBACK_LAUNCHER`
- [ ] Polimento tiles.png uso real, shake fino, D-pad Focus detalhado (pendente menor)

### Fase 3 — WebRTC P2P — ESQUELETO 2026-08-28
- [x] Stubs `lib/src/net/webrtc_manager.dart:1` `InMemoryWebRTCManager` + `lib/src/net/signaling_manager.dart:1` + `lib/src/ui/lobby_screen.dart:1` (sem deps ainda)
- [ ] Falta: add `flutter_webrtc: ^0.12`, `firebase_core`, `cloud_firestore` em `pubspec.yaml`, `firebase_options.dart`, `net_game_sync.dart` host authoritative 20Hz DataChannel, integrar `AppScreen.lobby` em `main.dart:39`

### Fase 4 — Spectator+Clip — ESQUELETO
- [x] `lib/src/clip/replay_buffer.dart:1` buffer 240 frames 8s
- [ ] Falta: câmera espectador (seguir vivos), `share_plus` clip export, `flutter build apk --release` signing

### V1.3 Futuro (não nesta entrega)
- [ ] IAP (`in_app_purchase` + Google Play Billing) — moedas pagas
- [ ] Online ranking global, ads

## Cronologia de Entregas
- 2026-08-28 00h: cria ROADMAP.md, inicia Fase 1
- 2026-08-28 06h: Fase 1 concluída — analyze 0, test 111 pass
- 2026-08-28 07h: Fase 2 arenas+leanback + stubs Fase3/4
- Próximo: Fase 3 deps webrtc+firebase → Fase 4 spectator/share → `v1.2` tag `flutter build web/apk`

## Como verificar progresso
```bash
flutter analyze && flutter test
flutter build apk --debug && flutter build web
```
Histórico de testes e `coverage/lcov.info` acompanham cada fase.

## Decisões Registradas
- 2026-08-28: WebRTC (não WebSocket), IAP adiado, Leanback sim, documentar tudo aqui.
