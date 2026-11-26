# Development plan

Each phase ends with a review. The next phase starts only after approval.

## Phase 1: Foundation (this branch)

- [x] Godot 4 project (portrait, mobile-friendly Compatibility renderer, Android ETC2/ASTC textures enabled)
- [x] Folder structure from the brief
- [x] Splash, welcome (guest play) and home screens
- [x] Mode selection (Classic / Snake) and player-count selection (2 or 4)
- [x] Local game lobby with player names and rules summary
- [x] Initial board: 15 x 15 layout, bases, track, safe stars, home columns, centre, pawns in bases
- [x] Pause menu, Android back button handling
- [x] Configurable rules data and match setup (no gameplay yet)
- [x] Test runner and tests for board geometry, match setup, rules config and screen smoke tests
- [x] GitHub Actions workflow running the tests headless

## Phase 2: Classic Ludo rules (done, awaiting review)

- [x] Dice with an injectable random generator, and a dice roll animation
- [x] `MatchState` + `LudoRules` (pure functions producing `GameEvent`s): start a pawn, legal moves, safe squares, captures, blocks (optional), home column, exact finish, extra turns (six, capture, finishing a pawn), three sixes, winner and ranking
- [x] Turn flow for 2 and 4 local players: tap the dice, tap a glowing pawn; the only possible move is made automatically; no-move turns pass
- [x] Pawns hop square by square; captured pawns fly back to base
- [x] Restart match (pause menu) and a match result screen with Play Again
- [x] Snakes & Ladders replaces Snake Ludo (owner decision): 1-100 board, one pawn per player, five original boards on a Choose Board screen, ladders up, snakes down (landing square only), exact roll for 100, six rolls again
- [x] Tighter game layout; Android debug APK built on every push; CI screenshots on the `ci-screenshots` branch
- [x] Tests: dice, legal movement, starting, safe squares, captures, home path, winning, three sixes, restart, no capture event without a capture; Snakes & Ladders squares, boards, ladders, snake heads, passing a snake, exact 100, ranking

## Phase 3: Character animation

- Character pawns with idle and walk animations, walking one square per step and facing the direction
- Capture sequence (raise hand, laser prop appears, cartoon laser, hit reaction, return to base, celebration), triggered only by a capture event
- Victory celebration
- Tests: laser sequence only after a successful capture

## Phase 4: Snakes & Ladders polish

- Animated snakes (idle motion) and a family-friendly slide animation for the characters
- More boards if wanted

## Phase 5: Polish and Android

- Sound effects and music (free-licensed), settings screen, help/rules screen, profile and history
- Performance pass, safe-area insets, several screen sizes
- Android export preset, debug APK, test on a real device

## Phase 6: Online and social

See `ONLINE_ARCHITECTURE.md`. Starts only once the offline game is stable.
