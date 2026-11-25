# Ludo Social

A family-friendly Ludo game for Android, built with **Godot 4** and **GDScript**. All tools and libraries are free and open source.

- **Classic Ludo**: 2 or 4 players, traditional rules (configurable).
- **Snake Ludo**: the same engine plus cartoon snakes that bite only when a pawn stops exactly on a snake's mouth.
- Offline pass-and-play first. Online play is planned (see `docs/ONLINE_ARCHITECTURE.md`) but not built.

Current status: **Phase 1 (Foundation)**. See `docs/DEVELOPMENT_PLAN.md`.

## Open the project

1. Install Godot **4.4.1** (standard build, not .NET): https://godotengine.org/download
2. In the Godot Project Manager choose **Import** and pick `ludo-social/project.godot`.
3. Press **F5** to run. The window opens at phone proportions (portrait, 720 x 1280 design size).

Escape on desktop acts like the Android back button.

## Run the tests

```sh
godot --headless --path ludo-social --import
godot --headless --path ludo-social res://tests/test_runner.tscn
```

The runner prints `PASS`/`FAIL` per test and exits with code 1 if anything fails. GitHub Actions runs the same commands on every push that touches `ludo-social/` (`.github/workflows/ludo-social.yml`).

The tests do not need any add-on; the runner is `tests/test_runner.gd`. Add a suite by creating `tests/unit/test_<name>.gd` that extends `res://tests/test_case.gd` and has `test_*` methods.

## Android build (Phase 5)

Not set up yet. Needed later, all free: Android SDK command-line tools, OpenJDK 17, Godot export templates 4.4.1. Signing keystores and passwords must **never** be committed; `.gitignore` already excludes `*.keystore`, `*.jks` and `export_credentials.cfg`.

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
