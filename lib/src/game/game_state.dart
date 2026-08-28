import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppScreen {
  menu,
  characterSelect,
  playing,
  paused,
  gameOver,
  shop,
  ranking,
  lobby,
}

class GameState {
  final AppScreen screen;
  final int selectedColorIndex;
  final List<int> humanSkins;
  final int humanCount;
  final String arenaId;
  final String? winnerName;
  final int round;
  final bool winnerIsHuman;

  const GameState({
    this.screen = AppScreen.menu,
    this.selectedColorIndex = 0,
    this.humanSkins = const [0],
    this.humanCount = 1,
    this.arenaId = 'classic',
    this.winnerName,
    this.round = 1,
    this.winnerIsHuman = false,
  });

  GameState copyWith({
    AppScreen? screen,
    int? selectedColorIndex,
    List<int>? humanSkins,
    int? humanCount,
    String? arenaId,
    String? winnerName,
    bool clearWinner = false,
    int? round,
    bool? winnerIsHuman,
  }) {
    return GameState(
      screen: screen ?? this.screen,
      selectedColorIndex: selectedColorIndex ?? this.selectedColorIndex,
      humanSkins: humanSkins ?? this.humanSkins,
      humanCount: humanCount ?? this.humanCount,
      arenaId: arenaId ?? this.arenaId,
      winnerName: clearWinner ? null : (winnerName ?? this.winnerName),
      round: round ?? this.round,
      winnerIsHuman: winnerIsHuman ?? this.winnerIsHuman,
    );
  }
}

class GameStateNotifier extends Notifier<GameState> {
  @override
  GameState build() => const GameState();

  void toMenu() => state = GameState(
    screen: AppScreen.menu,
    selectedColorIndex: state.selectedColorIndex,
    humanSkins: state.humanSkins,
    humanCount: state.humanCount,
    arenaId: state.arenaId,
    winnerName: null,
    round: 1,
    winnerIsHuman: false,
  );
  void toCharacterSelect() =>
      state = state.copyWith(screen: AppScreen.characterSelect);
  void toShop() => state = state.copyWith(screen: AppScreen.shop);
  void toRanking() => state = state.copyWith(screen: AppScreen.ranking);
  void toLobby() => state = state.copyWith(screen: AppScreen.lobby);
  void toPlaying() => state = state.copyWith(screen: AppScreen.playing);
  void toPaused() => state = state.copyWith(screen: AppScreen.paused);
  void toGameOver(String winner, {bool isHuman = false}) =>
      state = state.copyWith(
        screen: AppScreen.gameOver,
        winnerName: winner,
        winnerIsHuman: isHuman,
      );
  void selectColor(int i) {
    final skins = List<int>.from(state.humanSkins);
    if (skins.isEmpty) {
      skins.add(i);
    } else {
      skins[0] = i;
    }
    state = state.copyWith(selectedColorIndex: i, humanSkins: skins);
  }

  void setHumanSkins(List<int> skins) => state = state.copyWith(
    humanSkins: skins,
    selectedColorIndex: skins.isNotEmpty ? skins[0] : 0,
  );
  void setHumanCount(int c) {
    final count = c.clamp(1, 4);
    List<int> skins = List<int>.from(state.humanSkins);
    while (skins.length < count) {
      skins.add((skins.length * 2) % 6);
    }
    if (skins.length > count) skins = skins.sublist(0, count);
    state = state.copyWith(humanCount: count, humanSkins: skins);
  }

  void setArena(String id) => state = state.copyWith(arenaId: id);

  void nextRound() => state = state.copyWith(round: state.round + 1);
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(
  GameStateNotifier.new,
);

final playerColors = [
  0xFF00D1FF,
  0xFFFF3B30,
  0xFFFFCC00,
  0xFF4CD964,
  0xFFFF2D92,
  0xFF9D4EDD,
];
