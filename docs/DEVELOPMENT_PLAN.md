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

## Phase 2: Classic Ludo rules

- Dice with an injectable random generator, plus dice roll animation
- `MatchState` + `LudoRules`: start a pawn, legal moves, safe squares, captures, home column, exact finish, extra turns, three sixes, winner order
- Turn flow for 2 and 4 local players; tap a pawn to move; skip when no move
- Restart match; match result screen
- Tests: dice, legal movement, starting, safe squares, captures, home path, winning, restart

## Phase 3: Character animation

- Character pawns with idle and walk animations, walking one square per step and facing the direction
- Capture sequence (raise hand, laser prop appears, cartoon laser, hit reaction, return to base, celebration), triggered only by a capture event
- Victory celebration
- Tests: laser sequence only after a successful capture

## Phase 4: Snake Ludo

- Snake data (mouth square, body path) per board
- Snake art and idle motion; bite animation (family-friendly)
- Bite only on an exact landing on the mouth square; passing over does nothing; configured penalty applied
- Tests: mouth landing detection, passing over, penalty

## Phase 5: Polish and Android

- Sound effects and music (free-licensed), settings screen, help/rules screen, profile and history
- Performance pass, safe-area insets, several screen sizes
- Android export preset, debug APK, test on a real device

## Phase 6: Online and social

See `ONLINE_ARCHITECTURE.md`. Starts only once the offline game is stable.
