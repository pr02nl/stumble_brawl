# Stumble Brawl 💥

> Party brawler 1-4 players para **mobile e TV com controle**. Último vivo vence em arenas que desmoronam.

[![Flutter](https://img.shields.io/badge/Flutter-3.47-blue?logo=flutter)](https://flutter.dev)
[![Flame](https://img.shields.io/badge/Flame-1.38-red?logo=dart)](https://flame-engine.org)
[![Dart](https://img.shields.io/badge/Dart-3.13-blue)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Android%20TV-green)](https://flutter.dev)

`package: stumble_brawl` · `applicationId: br.nom.braga.oliveira.stumblebrawl` · Pasta física atual: `game/` (renomeie para `stumble_brawl/` quando desejar)

---

## 🎮 Sobre o jogo

Inspirado em **Stumble Guys + Brawl Stars**. Partidas rápidas de 60-75s, 4 jogadores (humanos + bots), física arcade com knockback que escala com dano, plataformas que caem e power-ups a cada 5s.

**Por que prende jovens?** Sessão curta, soco com física engraçada, skins colecionáveis, ranking e clipes compartilháveis. Roda no celular (touch) e na sala com **até 4 controles na TV**.

## ✨ Funcionalidades (V1.1)

| Feature | Detalhe |
|---|---|
| **Multiplayer local** | 1-4 humanos + bots = 4. Cada `gamepadId` vira 1 jogador (`MultiGamepadManager`). Teclado fallback para dev |
| **Skins + Loja** | 12 skins (6 grátis + 6 premium 50-200 moedas). `SkinManager` com `SharedPreferences` - compra, seleção, `+20 moedas` por vitória humana |
| **Power-ups** | 🍌 Banana (-25 dano), 🌀 Mola (super pulo -780), 🛡️ Escudo (3s invuln), 🚀 Turbo (boost 4s). Spawn em plataforma aleatória |
| **Áudio** | `flame_audio` + `audioplayers` - BGM loop + SFX pulo/soco/hit/queda/powerup/vitória com fallback se asset ausente |
| **Ranking** | `RankingManager` - vitórias, partidas, winRate, melhor dano, histórico 20 com data |

## 🛠️ Stack

| Pacote | Versão (2026-08-27) | Uso |
|---|---|---|
| `flutter` | 3.47.0 · Dart 3.13.0 | UI + Material 3 |
| `flame` | ^1.38.2 | Game loop, `HasCollisionDetection`, `PositionComponent` |
| `flame_audio` | ^2.12.2 | Áudio Flame |
| `audioplayers` | ^6.8.1 | Backend `ExoPlayer/Media3` no Android TV |
| `gamepads` | ^0.1.11 | Input bruto gamepad (stream `GamepadEvent`) |
| `flutter_riverpod` | ^3.4.2 | Estado `AppScreen` + seleção |
| `shared_preferences` | ^2.5.5 | Skins, coins, ranking |

`flutter pub outdated` → *direct dependencies: all up-to-date*.

## 📁 Estrutura

```
game/                         # renomeie para stumble_brawl/ se quiser
├── lib/
│   ├── main.dart              # ProviderScope + AppScreen router
│   └── src/
│       ├── game/              # stumble_brawl_game.dart, skin_manager.dart, ranking.dart, game_state.dart
│       ├── actors/            # player.dart, bot_controller.dart
│       ├── world/             # platform.dart, powerup.dart
│       ├── input/             # input_state.dart, multi_gamepad.dart
│       ├── audio/             # audio_manager.dart
│       └── ui/                # main_menu.dart, character_select.dart, game_screen.dart, shop_screen.dart, ranking_screen.dart, hud.dart
├── assets/
│   ├── audio/                 # jump.wav, punch.wav, hit.wav, fall.wav, powerup.wav, win.wav, bgm.mp3
│   └── images/
├── android/app/build.gradle.kts # namespace/applicationId br.nom.braga.oliveira.stumblebrawl
└── web/manifest.json          # Stumble Brawl PWA
```

## 🚀 Como rodar

```bash
# dependências
flutter pub get

# celular
flutter run -d android          # ou -d ios

# web
flutter run -d web-server --web-port 8081 --web-hostname 0.0.0.0
# ou
flutter run -d chrome

# build
flutter build web
flutter build apk --debug       # valida applicationId
flutter analyze && flutter test
```

## 🎮 Controles

| Ação | Celular (touch) | Gamepad / TV | Teclado PC |
|---|---|---|---|
| Mover | Setas ◀▶ + arraste central | Analógico esquerdo / D-pad | A/D ou ←/→ |
| Pular | Botão verde **PULO** | A / Cross / South (0) | SPACE / W / ↑ |
| Soco | Botão vermelho **SOCO** | X / Square / West (2) | J / X / ENTER |
| Pausa/Menu | X topo | Start / Back | ESC |

Dica TV: emparelhe controles via Bluetooth. Cada controle conectado aparece em `X controle(s)` no HUD e vira um humano; vagas viram bots.

## 🏆 Fluxo do jogo

`Menu → Personagens (1-4 humanos, skin por jogador) → Arena (11 plataformas, 5 falling) → Power-ups → Último vivo vence → +20 moedas se humano → Ranking/Loja`

Dano em `%` aumenta knockback: `scale = 1 + damage/80`. Com 80%+ qualquer soco joga longe. Cair abaixo de `y>850` elimina.

## 🔧 Configuração

*   **ApplicationId:** `br.nom.braga.oliveira.stumblebrawl` (`android/app/build.gradle.kts:8/19`, `ios/project.pbxproj`)
*   **Package name:** `br.nom.braga.oliveira.stumblebrawl` (`MainActivity.kt`)
*   **Web title:** `Stumble Brawl` (`web/index.html`, `manifest.json`)
*   Para renomear pasta física: `mv game stumble_brawl && cd stumble_brawl && flutter pub get`

## 📝 Assets

Placeholders vazios em `assets/audio/` já evitam crash (`AudioManager` ignora `FlameAudio` erro se arquivo ausente). Substitua por `.wav/.mp3` reais com mesmo nome.

## 📅 Roadmap

*   [x] MVP 1 humano + 3 bots, 1 arena, física, TV touch+gamepad
*   [x] V1.1 multi 1-4, skins/loja, power-ups, áudio, ranking
*   [ ] V1.2 online P2P, 3+ arenas, espectadores, share de clipe

## 📄 Licença

Privado (`publish_to: none`). Uso pessoal/portfolio.

---
Feito com Flutter + Flame · Para jovens que querem jogar na sala com controle.
