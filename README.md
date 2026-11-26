# RS Ludo

A family-friendly Ludo game for Android, built with **Godot 4** and **GDScript**. All tools and libraries are free and open source.

- **Classic Ludo**: 2 or 4 players, traditional rules (configurable).
- **Snakes & Ladders**: the traditional 1-100 race, one character per player, with five boards to choose from.
- Offline pass-and-play first. Online play is planned (see `docs/ONLINE_ARCHITECTURE.md`) but not built.

Current status: **Phase 2 (playable Classic Ludo and Snakes & Ladders, pass and play)**. See `docs/DEVELOPMENT_PLAN.md`.

## Open the project

1. Install Godot **4.4.1** (standard build, not .NET): https://godotengine.org/download
2. In the Godot Project Manager choose **Import** and pick `project.godot` in this repository.
3. Press **F5** to run. The window opens at phone proportions (portrait, 720 x 1280 design size).

Escape on desktop acts like the Android back button.

## Run the tests

```sh
godot --headless --path . --import
godot --headless --path . res://tests/test_runner.tscn
```

The runner prints `PASS`/`FAIL` per test and exits with code 1 if anything fails. GitHub Actions runs the same commands on every push and pull request (`.github/workflows/tests.yml`).

The tests do not need any add-on; the runner is `tests/test_runner.gd`. Add a suite by creating `tests/unit/test_<name>.gd` that extends `res://tests/test_case.gd` and has `test_*` methods.

## Google Play (automatic updates)

See `docs/PLAY_STORE_SETUP.md`: every change merged into `main` is uploaded to Google Play internal testing, and testers' phones update automatically.

## Android test APK

Every push builds a debug APK (`.github/workflows/android.yml`). Open the run under **Actions**, download `RsLUDO-debug-apk`, unzip and install it on the phone. Debug builds use a throwaway key; signing keys and passwords must **never** be committed (`.gitignore` excludes `*.keystore`, `*.jks` and `export_credentials.cfg`). A signed release build is part of Phase 5.

## Screenshots

The `Screenshots for review` CI job renders the main screens with `tools/screenshots.tscn` and puts them on the `ci-screenshots` branch.

## Folder layout

```
project.godot        engine settings, autoloads, portrait mobile display
scenes/screens/      one scene per screen (root Control + script)
scripts/autoload/    AppState (session), SceneRouter (navigation, back button), UiTheme
scripts/core/        rules-free logic: board geometry, rules config, players, match setup
scripts/modes/       Classic and Snake mode descriptions and default rules
scripts/board/       board drawing and pawn placeholders (presentation only)
scripts/ui/          palette, UI kit, reusable widgets, screen scripts
scripts/animations/  character/laser/snake animations (Phases 3-4)
scripts/net/         online boundary (Phase 6; does nothing offline)
assets/              replaceable art and sound, by area
tests/               test runner and unit suites
docs/                architecture and plan
```
