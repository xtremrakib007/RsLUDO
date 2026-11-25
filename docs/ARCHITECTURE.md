# Architecture

## Principles

1. **Rules and visuals are separate.** Game logic (`scripts/core`, and the Phase 2 rules engine) never touches nodes, tweens or drawing. Visual code (`scripts/board`, `scripts/animations`, `scripts/ui`) only shows what the logic decided. This lets us test the rules headless, replace art freely and, later, run the same rules on a server.
2. **Rules are data.** `LudoRulesConfig` holds every house rule (start rolls, extra turns, three-sixes, safe squares, blocks, snake penalty). Variations are new data, not new code.
3. **One engine, two modes.** `GameMode` subclasses (`ClassicMode`, `SnakeMode`) only supply text, colours and default rules. Snake Ludo adds a snake layer on top of the same engine in Phase 4.
4. **Small files with one job.** No single large game script.

## Layers

```
UI screens (scripts/ui/screens)      build controls, navigate, show results
   |  reads MatchConfig, shows BoardView
Presentation (scripts/board, scripts/animations)
   |  BoardView draws BoardLayout geometry; PawnToken is the pawn placeholder
Core logic (scripts/core)            BoardLayout, LudoRulesConfig, LudoPlayer, MatchConfig
   |  Phase 2 adds: Dice (injectable RNG), MatchState, LudoRules (legal moves, apply move -> events)
Online boundary (scripts/net)        OnlineService (unavailable offline)
```

### Board geometry (`BoardLayout`)

- 15 x 15 grid, cells are `Vector2i(column, row)`.
- Seats clockwise: 0 top-left (Red), 1 top-right (Green), 2 bottom-right (Yellow), 3 bottom-left (Blue). Two-player games use seats 0 and 2.
- 52 track squares; index 0 is seat 0's start square `(1, 6)`. Each seat's start index is `seat * 13`.
- A pawn's **progress** is relative to its own start: 0-50 track, 51-55 home column, 56 finish. The Phase 2 engine works only in progress values; `BoardLayout.progress_point()` turns them into board positions.
- Safe squares: each start square and the star square 8 steps after it.
- Every seat's geometry is seat 0's rotated by quarter turns, which the tests check.

### Planned Phase 2 engine shape

- `Dice`: wraps a `RandomNumberGenerator` that tests can seed. Online, the server rolls instead.
- `MatchState`: plain data (whose turn, each pawn's progress, consecutive sixes, finished order). Serializable for saves and network sync.
- `LudoRules`: pure functions: `legal_moves(state, roll)`, `apply_move(state, move) -> Array[GameEvent]`.
- **Events** (`PawnMoved{path}`, `PawnCaptured{by, victim}`, `SnakeBite{...}`, `PawnFinished`, `ExtraTurn`, `TurnPassed`, `GameWon`) are what the presentation plays back. The laser capture animation is triggered **only** by a `PawnCaptured` event, so it cannot play for a failed capture, and that is unit-testable without rendering.

### Animation plan (Phases 3-4)

- `PawnToken` is replaced by a character scene (`AnimatedSprite2D` or a `Skeleton2D` rig) with `idle`, `walk`, `celebrate`, `hit` and `capture` states. The board only sets position, facing and state, so the swap stays local.
- Walking plays one tween per square along the `PawnMoved.path`, facing each step's direction.
- The laser prop is a separate node that the capture sequence shows and hides. It is not part of the walk state.
- 3D later: the board and characters sit behind small view interfaces (`BoardView`, the pawn node), so a 3D view can read the same `BoardLayout` and events.

### Assets

`assets/<area>/` holds replaceable art and sound. Phase 1 draws everything in code (board, pawns, dice, mode art), so the game runs with no binary assets. Final art replaces the drawing in `PawnToken`, `ModeArt` and `DiceFace` without changing callers.

## Navigation

`SceneRouter` (autoload) maps screen ids to scenes, fades between them, and sends the Android back button (and Escape) to the current screen's `handle_back()`.

| Screen | Status in Phase 1 |
| --- | --- |
| Splash | done |
| Welcome + Play as Guest | done (guest name stored in `user://profile.cfg`) |
| Home | done; online tiles and Profile/Settings/Rules show "coming" messages |
| Classic / Snake selection | Home mode cards, plus mode details on the player-count screen |
| Player-count selection | done (2 or 4) |
| Game lobby | done (names, rules summary) |
| Game board | board, pawns in bases, pause menu (Resume / Restart / Quit) |
| Match result, Profile, History, Settings, Help | later phases |
