# Flappy Stock — Claude Code Implementation Guide

## Overview

Flappy Stock is a Flappy Bird–style game built with Flutter + Flame where the obstacles are real stock market candlestick charts. The bird navigates through candles fetched from J-Quants API. The goal is to pass through all candles in a stage; score is determined by how close the bird's Y-position matches the candle's price range as it passes.

## Directory Structure

```
lib/
├── main.dart                         # Entry point — runApp(GameApp())
└── src/
    ├── flappy_stock.dart             # FlameGame (HasCollisionDetection + KeyboardEvents)
    ├── flappy_world.dart             # World (TapCallbacks, pipe/candle management, camera)
    ├── config.dart                   # All constants (dimensions, physics)
    ├── data/
    │   ├── pipe_data.dart            # CandleData / StageData models
    │   └── pipe_loader.dart          # JSON asset loader + spawnX normalizer
    ├── components/
    │   ├── components.dart           # Barrel export for all components
    │   ├── bird.dart                 # Bird (CircleComponent + CollisionCallbacks)
    │   ├── candle.dart               # Candle obstacle (PositionComponent, renders OHLC)
    │   ├── ground.dart               # Ground + GroundTile (tiling, hitbox)
    │   └── background.dart           # Stock-chart–style grid background
    └── widgets/
        ├── game_app.dart             # Flutter MaterialApp wrapper, overlay map
        ├── score_card.dart           # Score display (ValueNotifier–driven)
        ├── overlay_screen.dart       # Welcome / Game Over / Clear UI
        └── stage_select_screen.dart  # Stage selection list

assets/data/pipes/   # Stage JSON files (candle data)
  ├── stage_01.json  # Tutorial (hand-crafted coordinates)
  ├── stage_02.json  # Tutorial stage 2
  ├── 5255_daily.json   # Real stock data (Unix timestamp spawnX, scaled at runtime)
  ├── 5255_weekly.json
  └── 5255_monthly.json

packages/jquants_client/  # Standalone Dart package — stock data fetcher
  ├── lib/jquants/
  │   ├── jquants_auth.dart         # API key auth
  │   ├── jquants_client.dart       # HTTP client for J-Quants API v2
  │   ├── jquants_service.dart      # Higher-level service (fetch + resample)
  │   ├── ohlcv_model.dart          # OhlcvData model
  │   └── ohlcv_resampler.dart      # Resample daily → weekly/monthly
  ├── bin/
  │   ├── jquants_client.dart       # CLI: fetch stock data → output/{code}/{period}.json
  │   └── convert_to_stage.dart     # CLI: convert output/ → assets/data/pipes/*.json
  └── output/                       # Fetched raw data (not committed to assets directly)
```

## State Machine

```
[welcome] ──tap/space──> [stageSelect] ──stage selected──> [playing]
                                                               │
                                                   all candles passed
                                                               │
[gameOver] <── (reserved, not yet triggered) ──>          [clear]
    └──tap/space──> [stageSelect]                             └──tap/space──> [stageSelect]
```

`FlappyStock.playState` setter auto-manages `overlays.add/remove` for each state. Each state name maps to an entry in `GameApp`'s `overlayBuilderMap`.

## Coordinate Systems

Two coordinate systems are in use — understanding this is critical when editing candle or background rendering:

| System | Origin | Y direction | Usage |
|--------|--------|-------------|-------|
| **JSON** | bottom-left of visible area | up is positive | `CandleData` fields: `high`, `low`, `open`, `close` |
| **Flame** | top-left | down is positive | All `PositionComponent` positions |

Conversion (applied in `Candle.render`):
```dart
flameY = stageHeight - jsonY * 3   // *3 because stageHeight = visibleHeight * 3
jsonY  = (stageHeight - flameY) / 3
```

Valid JSON Y-coordinate range: `0 <= low <= open/close <= high <= stageHeight / 3`
(`stageHeight / 3` ≈ 616 game units at current config)

## Key Constants (`lib/src/config.dart`)

| Constant | Value | Description |
|----------|-------|-------------|
| `gameWidth` | 400.0 | Fixed canvas width |
| `gameHeight` | 700.0 | Fixed viewport height |
| `stageHeight` | `(gameHeight - groundHeight) * 3` | Full scrollable stage height |
| `groundHeight` | `gameHeight * 0.12` | Height of ground bar |
| `pipeWidth` | `gameWidth * 0.10` | Width of each candle |
| `pipeSpeed` | `gameWidth * 0.55` | Default scroll speed (overridden per stage) |
| `birdRadius` | `gameWidth * 0.07` | Bird collision radius |
| `gravity` | `gameHeight * 1.25` | Downward acceleration |
| `maxFlapHoldTime` | 0.5s | Max flap hold duration |

## Game Mechanics

### Bird Physics
- Hold tap/space → upward lift increases quadratically with hold time
- Release → gravity takes over
- Bounded between y=0 (ceiling) and y=stageHeight (ground): velocity zeroed, no game over
- Tilt angle is proportional to vertical velocity

### Candle Scoring
- Score increments as each candle's right edge passes the bird's X-position (`gameWidth * 0.25`)
- Score value = `jsonY.round()` (bird's Y in JSON coords), added only if the bird is within the candle's wick range (`low <= jsonY <= high`)
- `onScored` callback from `Candle` → `FlappyWorld._onCandleScored()` → triggers `PlayState.clear` after all candles pass

### Candle Spawning
- `FlappyWorld._traveledX` accumulates `pipeSpeed * dt` each frame
- When `_traveledX >= _pendingCandles.first.spawnX`, a `Candle` is created and added to the world
- Candles scroll left at `pipeSpeed`; removed when `position.x < -pipeWidth * 2`

### Camera Tracking
- Camera follows bird's Y-position (vertical scrolling stage)
- `viewfinder.position.y` is clamped so it never shows outside the stage

## Stage JSON Format

```json
{
  "id": "stage_01",
  "name": "Stage 1: Tutorial",
  "pipeSpeed": 150.0,
  "candles": [
    { "spawnX": 600, "high": 490, "low": 150, "open": 240, "close": 410 }
  ]
}
```

- **`spawnX`**: In tutorial stages, this is a game-coordinate value (pixels traveled). In real stock stages (e.g., `5255_daily`), it is a Unix timestamp in seconds — `PipeLoader` detects this automatically and normalizes.
- **`pipeSpeed`**: Per-stage scroll speed. Overrides the global default `pipeSpeed` constant.
- **OHLC values**: JSON coordinate system (bottom=0). `PipeLoader` validates OHLC consistency on load via `assert`.

### spawnX Normalization (`PipeLoader._normalizeSpawnX`)
When average interval between candles exceeds `_rawDataThreshold` (10,000 units), the data is treated as Unix timestamps and scaled so:
- First candle appears at `_targetFirstSpawnX` (600px traveled)
- Average spacing becomes `_targetInterval` (450px)

## Flame API Conventions

- `TapCallbacks` → mixin on `FlappyWorld` (`World` subclass), **not** on `FlameGame`
- `KeyboardEvents` → mixin on `FlappyStock` (`FlameGame` subclass); handles space bar
- `HasCollisionDetection` → on `FlappyStock` (FlameGame); required for hitbox detection to work
- `HasGameReference<FlappyStock>` → on all components that need game state; access via `.game`
- `GroundTile`: extends `RectangleComponent`, adds `RectangleHitbox()` in `onLoad` (cannot use `with RectangleHitbox` due to constructor conflicts)
- `Bird` has `CollisionCallbacks` and a `CircleHitbox(radius: 1)` — infrastructure is in place for collision-triggered game over but not yet implemented

## Development Workflow

```bash
# Run on Chrome (primary target)
make run          # flutter run -d chrome

# Production build
make build        # flutter build web --release

# Deploy to Firebase Hosting
make deploy       # build + firebase deploy --only hosting
```

**Flame has no hot reload** — after code changes use `R` (full restart) in the Flutter CLI, not `r`.

## CI/CD

- Push to `main` → GitHub Actions runs `make build` then deploys to Firebase Hosting project `flappy-stock-prod`
- Required secret: `FIREBASE_SERVICE_ACCOUNT_FLAPPY_STOCK_PROD`

## Adding Real Stock Data

1. In `packages/jquants_client`, set `JQUANTS_API_KEY` environment variable (or pass to auth)
2. Run the fetch CLI:
   ```bash
   cd packages/jquants_client
   dart run bin/jquants_client.dart  # fetches to output/{code}/{period}.json
   ```
3. Convert to stage format:
   ```bash
   dart run bin/convert_to_stage.dart  # writes to ../../assets/data/pipes/
   ```
4. The new JSON file is auto-discovered at runtime — no code changes needed

## Adding a New Stage (Manual)

1. Create `assets/data/pipes/my_stage.json` following the stage JSON format above
2. Use JSON Y-coordinates (bottom=0, max ≈ 616)
3. The file is auto-loaded by `PipeLoader` (reads all `assets/data/pipes/*.json` from `AssetManifest`)
4. No code changes required — stages appear in the `StageSelectScreen` automatically

## Implementation Notes

### Collision / Ground
- Ground tile hitbox exists but `Bird.onCollisionStart` is not overridden → no collision-triggered game over currently
- Ground/ceiling bounds are enforced by Y-position clamping in `Bird.update`

### Component Removal Timing
- `removeFromParent()` is queued: components removed this frame may still appear in `children.query<>()` until the next frame

### Candle Render Coordinate Math
```dart
final flameHigh  = stageHeight - high  * 3;   // JSON top → Flame top
final flameLow   = stageHeight - low   * 3;   // JSON bottom → Flame bottom
final bodyTop    = min(flameOpen, flameClose); // upper body edge in Flame coords
final bodyBottom = max(flameOpen, flameClose);
```

Bullish (yang) candles are teal (`0xFF26A69A`); bearish (yin) are red (`0xFFEF5350`).

### Background Grid
- Horizontal grid lines every 50 JSON-Y units, with price labels on the right edge
- Vertical grid lines scroll in sync with `game.pipeScrollOffset % gridIntervalX`

### Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| `flame` | ^1.28.1 | Game engine |
| `flutter_animate` | ^4.5.2 | Overlay entrance animations |
| `google_fonts` | ^8.0.2 | Press Start 2P font for UI |
