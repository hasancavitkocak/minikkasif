import 'package:flutter/material.dart';

import '../theme.dart';
import 'clock_game.dart';
import 'coloring_game.dart';
import 'count_game.dart';
import 'diff_game.dart';
import 'dots_game.dart';
import 'game_def.dart';
import 'groups_game.dart';
import 'jobs_game.dart';
import 'letters_game.dart';
import 'maze_game.dart';
import 'memory_game.dart';
import 'odd_game.dart';
import 'pattern_game.dart';
import 'puzzle_game.dart';
import 'seasons_game.dart';
import 'shadow_game.dart';
import 'shapes_game.dart';
import 'simon_game.dart';
import 'sort_game.dart';
import '../screens/duel_screen.dart';
import '../screens/music_screen.dart';
import '../screens/scene_screen.dart';
import '../screens/story_screen.dart';
import '../screens/wardrobe_screen.dart';
import '../widgets/game_shell.dart';

/// Ana menüdeki mini oyunlar. İlk ikisi ücretsiz, diğerleri abonelikle açılır.
final games = <GameDef>[
  GameDef(
    id: 'shapes',
    emoji: '🔺',
    color: AppColors.red,
    free: true,
    builder: (g, level) => ShapesGame(game: g, level: level),
  ),
  GameDef(
    id: 'memory',
    emoji: '🃏',
    color: AppColors.blue,
    free: true,
    levels: 3 * worldSize,
    builder: (g, level) => WorldScope(
      level: level,
      child: MemoryGame(game: g, level: stageOf(level)),
    ),
  ),
  GameDef(
    id: 'maze',
    emoji: '🧭',
    color: const Color(0xFF7CC576),
    builder: (g, level) => MazeGame(game: g, level: level),
  ),
  GameDef(
    id: 'color',
    emoji: '🎨',
    color: const Color(0xFFFF8A65),
    builder: (g, level) => ColoringGame(game: g, level: level),
  ),
  GameDef(
    id: 'shadow',
    emoji: '🦆',
    color: AppColors.purple,
    levels: 3 * worldSize,
    builder: (g, level) => WorldScope(
      level: level,
      child: ShadowGame(game: g, level: stageOf(level)),
    ),
  ),
  GameDef(
    id: 'count',
    emoji: '🔢',
    color: AppColors.green,
    levels: 3 * worldSize,
    builder: (g, level) => WorldScope(
      level: level,
      child: CountGame(game: g, level: stageOf(level)),
    ),
  ),
  GameDef(
    id: 'groups',
    emoji: '🧺',
    color: const Color(0xFF4FC3F7),
    builder: (g, level) => GroupsGame(game: g, level: level),
  ),
  GameDef(
    id: 'pattern',
    emoji: '📿',
    color: AppColors.orange,
    levels: 3 * worldSize,
    builder: (g, level) => WorldScope(
      level: level,
      child: PatternGame(game: g, level: stageOf(level)),
    ),
  ),
  GameDef(
    id: 'odd',
    emoji: '🐸',
    color: AppColors.teal,
    levels: 3 * worldSize,
    builder: (g, level) => WorldScope(
      level: level,
      child: OddGame(game: g, level: stageOf(level)),
    ),
  ),
  GameDef(
    id: 'diff',
    emoji: '🔍',
    color: const Color(0xFFFFB74D),
    levels: 3 * worldSize,
    builder: (g, level) => WorldScope(
      level: level,
      child: DiffGame(game: g, level: stageOf(level)),
    ),
  ),
  GameDef(
    id: 'puzzle',
    emoji: '🧩',
    color: AppColors.pink,
    builder: (g, level) => PuzzleGame(game: g, level: level),
  ),
  GameDef(
    id: 'sort',
    emoji: '🧸',
    color: AppColors.yellow,
    levels: 3 * worldSize,
    builder: (g, level) => WorldScope(
      level: level,
      child: SortGame(game: g, level: stageOf(level)),
    ),
  ),
  GameDef(
    id: 'simon',
    emoji: '🎵',
    color: const Color(0xFF7986CB),
    builder: (g, level) => SimonGame(game: g, level: level),
  ),
  GameDef(
    id: 'dots',
    emoji: '✏️',
    color: const Color(0xFF26A69A),
    builder: (g, level) => DotsGame(game: g, level: level),
  ),
  GameDef(
    id: 'jobs',
    emoji: '🧑‍🚒',
    color: const Color(0xFFEF5350),
    builder: (g, level) => JobsGame(game: g, level: level),
  ),
  GameDef(
    id: 'seasons',
    emoji: '🍂',
    color: const Color(0xFFFFA726),
    builder: (g, level) => SeasonsGame(game: g, level: level),
  ),
  GameDef(
    id: 'clock',
    emoji: '🕒',
    color: const Color(0xFF42A5F5),
    builder: (g, level) => ClockGame(game: g, level: level),
  ),
  GameDef(
    id: 'letters',
    emoji: '🔤',
    color: const Color(0xFFAB47BC),
    builder: (g, level) => LettersGame(game: g, level: level),
  ),
];

/// Bölümü ve yıldızı olmayan serbest etkinlikler; ana ekranda oyunlardan
/// sonra gelir ve herkese açıktır.
final activities = <GameDef>[
  GameDef(
    id: 'scene',
    emoji: '🖼️',
    color: const Color(0xFF66BB6A),
    levels: 0,
    builder: (_, _) => const SceneScreen(),
  ),
  GameDef(
    id: 'duel',
    emoji: '👫',
    color: const Color(0xFF5C9DFF),
    levels: 0,
    builder: (_, _) => const DuelScreen(),
  ),
  GameDef(
    id: 'music',
    emoji: '🎶',
    color: const Color(0xFFFF8FB1),
    levels: 0,
    builder: (_, _) => const MusicScreen(),
  ),
  GameDef(
    id: 'wardrobe',
    emoji: '🎩',
    color: const Color(0xFFFFB74D),
    levels: 0,
    builder: (_, _) => const WardrobeScreen(),
  ),
  GameDef(
    id: 'story',
    emoji: '📖',
    color: const Color(0xFF8D6E63),
    levels: 0,
    builder: (_, _) => const StoryScreen(),
  ),
];
