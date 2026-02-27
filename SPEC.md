# Flappy Bird — Flutter/Flame 実装仕様書

> Claude Code への引き継ぎ用ドキュメント  
> 参照元: Google Codelabs (Brick Breaker), https://docs.flame-engine.org/latest/

---

## 0. 前提・技術選定

| 項目 | 内容 |
|---|---|
| フレームワーク | Flutter (Web ターゲット) |
| ゲームエンジン | Flame ^1.28.1 |
| レンダラー | CanvasKit（`--web-renderer canvaskit`） |
| 言語 | Dart |
| 補助パッケージ | flutter_animate ^4.5.2, google_fonts ^6.2.1 |

### ⚠️ 使用する最新 Flame API（古い書き方との対応）

| 非推奨（古い） | 現在の正しい書き方 |
|---|---|
| `TapDetector`（FlameGame mixin） | `TapCallbacks`（World サブクラスに追加） |
| `HasGameRef` / `.gameRef` | `HasGameReference<T>` / `.game` |
| `SpawnComponent`（パイプ生成） | JSON定義 + `_traveledX` によるキュー管理 |
| `GameWidget.controlled` | `StatefulWidget` 内で game インスタンス管理 |

---

## 1. ディレクトリ構成

```
flappy_bird/
├── pubspec.yaml
├── assets/
│   ├── data/
│   │   └── pipes.json          # パイプ配置定義（静的ファイル）
│   └── images/                 # スプライト画像（省略可・図形で代替可）
└── lib/
    ├── main.dart
    └── src/
        ├── flappy_bird.dart     # FlameGame サブクラス
        ├── flappy_world.dart    # World サブクラス（タップ受付・パイプ管理）
        ├── config.dart          # 全定数
        ├── data/
        │   ├── pipe_data.dart   # StageData / PipeData モデル
        │   └── pipe_loader.dart # JSON ローダー
        ├── components/
        │   ├── components.dart  # barrel export
        │   ├── bird.dart        # プレイヤー（鳥）
        │   ├── pipe_pair.dart   # 上下パイプペア
        │   ├── ground.dart      # 地面（タイリングスクロール）
        │   └── background.dart  # 背景（ParallaxComponent）
        └── widgets/
            ├── game_app.dart        # Flutter ラッパー（GameWidget 埋め込み）
            ├── score_card.dart      # スコア表示（ValueNotifier 連携）
            └── overlay_screen.dart  # ウェルカム / ゲームオーバー UI
```

---

## 2. pubspec.yaml

```yaml
name: flappy_bird
description: "Flappy Bird built with Flutter + Flame"
publish_to: "none"
version: 0.1.0

environment:
  sdk: ^3.8.0

dependencies:
  flutter:
    sdk: flutter
  flame: ^1.28.1
  flutter_animate: ^4.5.2
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/data/pipes.json
    - assets/images/
```

---

## 3. assets/data/pipes.json（パイプ配置定義）

```json
{
  "stages": [
    {
      "id": "stage_01",
      "comment": "チュートリアル：隙間広め・ゆっくり",
      "pipeSpeed": 150.0,
      "pipes": [
        { "spawnX": 600,  "gapCenterY": 350 },
        { "spawnX": 1050, "gapCenterY": 300 },
        { "spawnX": 1500, "gapCenterY": 400 },
        { "spawnX": 1950, "gapCenterY": 280 },
        { "spawnX": 2400, "gapCenterY": 370 }
      ]
    },
    {
      "id": "stage_02",
      "comment": "本番：隙間標準・速度アップ",
      "pipeSpeed": 220.0,
      "pipes": [
        { "spawnX": 600,  "gapCenterY": 320 },
        { "spawnX": 1000, "gapCenterY": 430 },
        { "spawnX": 1400, "gapCenterY": 250 },
        { "spawnX": 1800, "gapCenterY": 390 },
        { "spawnX": 2200, "gapCenterY": 310 },
        { "spawnX": 2600, "gapCenterY": 450 }
      ]
    }
  ]
}
```

**フィールド定義：**

| フィールド | 型 | 説明 |
|---|---|---|
| `stages[].id` | String | ステージ識別子 |
| `stages[].pipeSpeed` | double | パイプの横スクロール速度（仮想px/秒） |
| `stages[].pipes[].spawnX` | double | 鳥の累積移動距離がこの値に達したとき出現 |
| `stages[].pipes[].gapCenterY` | double | 隙間の中心Y座標（仮想px） |

**gapCenterY の有効範囲：**  
`pipeGap / 2 < gapCenterY < gameHeight - groundHeight - pipeGap / 2`

---

## 4. lib/src/config.dart

```dart
const gameWidth  = 400.0;
const gameHeight = 700.0;

// 鳥
const birdRadius   = gameWidth * 0.07;
const gravity      = gameHeight * 2.5;
const flapImpulse  = -gameHeight * 0.65;

// パイプ
const pipeWidth    = gameWidth * 0.18;
const pipeGap      = gameHeight * 0.26;  // 隙間の高さ
const pipeSpeed    = gameWidth * 0.55;   // デフォルト速度（JSON で上書き）

// 地面
const groundHeight = gameHeight * 0.12;
const groundSpeed  = pipeSpeed;          // パイプと同速
```

---

## 5. lib/src/data/pipe_data.dart

```dart
class PipeData {
  const PipeData({
    required this.spawnX,
    required this.gapCenterY,
  });

  final double spawnX;
  final double gapCenterY;

  factory PipeData.fromJson(Map<String, dynamic> json) => PipeData(
    spawnX:     (json['spawnX']     as num).toDouble(),
    gapCenterY: (json['gapCenterY'] as num).toDouble(),
  );
}

class StageData {
  const StageData({
    required this.id,
    required this.pipeSpeed,
    required this.pipes,
  });

  final String id;
  final double pipeSpeed;
  final List<PipeData> pipes;

  factory StageData.fromJson(Map<String, dynamic> json) => StageData(
    id:        json['id'] as String,
    pipeSpeed: (json['pipeSpeed'] as num).toDouble(),
    pipes: (json['pipes'] as List)
        .map((p) => PipeData.fromJson(p as Map<String, dynamic>))
        .toList(),
  );
}
```

---

## 6. lib/src/data/pipe_loader.dart

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'pipe_data.dart';
import '../config.dart';

class PipeLoader {
  static Future<List<StageData>> load() async {
    final raw = await rootBundle.loadString('assets/data/pipes.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final stages = (json['stages'] as List)
        .map((s) => StageData.fromJson(s as Map<String, dynamic>))
        .toList();

    // バリデーション
    for (final stage in stages) {
      for (final pipe in stage.pipes) {
        assert(
          pipe.gapCenterY > pipeGap / 2 &&
          pipe.gapCenterY < gameHeight - groundHeight - pipeGap / 2,
          '[${stage.id}] gapCenterY out of range: ${pipe.gapCenterY}',
        );
      }
    }
    return stages;
  }
}
```

---

## 7. lib/src/flappy_bird.dart（FlameGame）

```dart
import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'flappy_world.dart';
import 'config.dart';

enum PlayState { welcome, playing, gameOver }

class FlappyBird extends FlameGame {
  FlappyBird()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: gameWidth,
          height: gameHeight,
        ),
        world: FlappyWorld(),
      );

  // Flutter 状態管理との橋渡し
  final ValueNotifier<int> score = ValueNotifier(0);

  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState state) {
    _playState = state;
    switch (state) {
      case PlayState.welcome:
      case PlayState.gameOver:
        overlays.add(state.name);
      case PlayState.playing:
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.gameOver.name);
    }
  }

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    playState = PlayState.welcome;
  }

  @override
  Color backgroundColor() => const Color(0xff87CEEB);
}
```

---

## 8. lib/src/flappy_world.dart（World）

```dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'flappy_bird.dart';
import 'config.dart';
import 'data/pipe_data.dart';
import 'data/pipe_loader.dart';
import 'components/components.dart';

class FlappyWorld extends World
    with TapCallbacks, HasGameReference<FlappyBird> {

  List<StageData> _stages = [];
  StageData? _currentStage;

  // 未出現パイプのキュー（spawnX 昇順）
  final List<PipeData> _pendingPipes = [];

  // 鳥の仮想累積移動距離
  double _traveledX = 0;

  @override
  FutureOr<void> onLoad() async {
    _stages = await PipeLoader.load();
    add(Background());
    add(Ground());
  }

  // ─── ゲーム開始 ────────────────────────────────────────────────
  void _startGame() {
    removeAll(children.query<Bird>());
    removeAll(children.query<PipePair>());

    game.score.value = 0;
    _traveledX = 0;

    // ステージ選択（現在は stage_01 固定。後で拡張可）
    _currentStage = _stages.first;

    // キューを初期化
    _pendingPipes
      ..clear()
      ..addAll(_currentStage!.pipes);

    game.playState = PlayState.playing;

    add(Bird(
      position: Vector2(gameWidth * 0.25, gameHeight * 0.45),
    ));
  }

  // ─── ゲームループ ──────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    final speed = _currentStage?.pipeSpeed ?? pipeSpeed;
    _traveledX += speed * dt;

    // 出現タイミングに達したパイプを追加
    while (_pendingPipes.isNotEmpty &&
           _traveledX >= _pendingPipes.first.spawnX) {
      final data = _pendingPipes.removeAt(0);
      add(PipePair(
        gapCenterY: data.gapCenterY,
        speed: speed,
      ));
    }
  }

  // ─── タップ入力 ────────────────────────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (game.playState != PlayState.playing) {
      _startGame();
    } else {
      children.query<Bird>().firstOrNull?.flap();
    }
  }
}
```

---

## 9. lib/src/components/bird.dart

```dart
import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../flappy_bird.dart';
import '../config.dart';
import 'pipe_pair.dart';
import 'ground.dart';

class Bird extends CircleComponent
    with CollisionCallbacks, HasGameReference<FlappyBird> {

  Bird({required super.position})
    : super(
        radius: birdRadius,
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0xffFFD700)
          ..style = PaintingStyle.fill,
        children: [CircleHitbox()],
      );

  final Vector2 _velocity = Vector2.zero();

  void flap() => _velocity.y = flapImpulse;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    _velocity.y += gravity * dt;
    position += _velocity * dt;

    // 傾き演出（速度に比例して回転）
    angle = (_velocity.y * 0.002).clamp(-0.5, 1.2);

    // 天井に当たったら跳ね返し
    if (position.y - radius <= 0) {
      _velocity.y = 0;
      position.y = radius;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PipePair || other is GroundTile) {
      add(RemoveEffect(
        delay: 0.3,
        onComplete: () => game.playState = PlayState.gameOver,
      ));
    }
  }
}
```

---

## 10. lib/src/components/pipe_pair.dart

```dart
import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_bird.dart';
import '../config.dart';

class PipePair extends PositionComponent
    with HasGameReference<FlappyBird> {

  PipePair({
    required this.gapCenterY,
    required this.speed,
  }) : super(
    position: Vector2(gameWidth + pipeWidth, 0),
    anchor: Anchor.topLeft,
  );

  final double gapCenterY;
  final double speed;
  bool _scored = false;

  static const _pipeColor = Color(0xff5aad3e);

  @override
  FutureOr<void> onLoad() async {
    // 上パイプ
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(pipeWidth, gapCenterY - pipeGap / 2),
      paint: Paint()..color = _pipeColor,
      children: [RectangleHitbox()],
    ));

    // 下パイプ
    final bottomY = gapCenterY + pipeGap / 2;
    add(RectangleComponent(
      position: Vector2(0, bottomY),
      size: Vector2(pipeWidth, gameHeight - bottomY),
      paint: Paint()..color = _pipeColor,
      children: [RectangleHitbox()],
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speed * dt;

    // スコア加算：鳥の位置（gameWidth * 0.25）をパイプ右端が通過した瞬間
    if (!_scored && position.x + pipeWidth < gameWidth * 0.25) {
      _scored = true;
      game.score.value++;
    }

    // 画面左端を超えたら削除
    if (position.x < -pipeWidth * 2) removeFromParent();
  }
}
```

---

## 11. lib/src/components/ground.dart

```dart
import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_bird.dart';
import '../config.dart';

// 衝突判定の対象として識別するためのラッパークラス
class GroundTile extends RectangleComponent with RectangleHitbox {
  GroundTile({required super.position, required super.size})
    : super(paint: Paint()..color = const Color(0xffd7b25e));
}

class Ground extends PositionComponent
    with HasGameReference<FlappyBird> {

  @override
  FutureOr<void> onLoad() async {
    // 2枚並べてタイリング
    for (var i = 0; i < 2; i++) {
      add(GroundTile(
        position: Vector2(gameWidth * i, gameHeight - groundHeight),
        size: Vector2(gameWidth, groundHeight),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    for (final tile in children.query<GroundTile>()) {
      tile.position.x -= groundSpeed * dt;
      // 左端を超えたら右端へ移動（無限ループ）
      if (tile.position.x <= -gameWidth) {
        tile.position.x += gameWidth * 2;
      }
    }
  }
}
```

---

## 12. lib/src/components/background.dart

```dart
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config.dart';

// 画像アセットが未用意の場合はグラデーション矩形で代替
class Background extends RectangleComponent {
  Background()
    : super(
        position: Vector2.zero(),
        size: Vector2(gameWidth, gameHeight),
        paint: Paint()..color = const Color(0xff87CEEB),
      );

  // 画像アセット使用時は ParallaxComponent に差し替え:
  //
  // class Background extends ParallaxComponent<FlappyBird> {
  //   @override
  //   FutureOr<void> onLoad() async {
  //     parallax = await game.loadParallax(
  //       [ParallaxImageData('bg_sky.png'), ParallaxImageData('bg_clouds.png')],
  //       baseVelocity: Vector2(20, 0),
  //       velocityMultiplierDelta: Vector2(1.8, 0),
  //     );
  //   }
  // }
}
```

---

## 13. lib/src/components/components.dart（barrel export）

```dart
export 'background.dart';
export 'bird.dart';
export 'ground.dart';
export 'pipe_pair.dart';
```

---

## 14. lib/src/widgets/score_card.dart

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.score});

  final ValueNotifier<int> score;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: score,
      builder: (context, value, _) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Text(
          'SCORE: $value',
          style: GoogleFonts.pressStart2p(
            fontSize: 18,
            color: const Color(0xff184e77),
          ),
        ),
      ),
    );
  }
}
```

---

## 15. lib/src/widgets/overlay_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.pressStart2p(
      fontSize: 28,
      color: const Color(0xff184e77),
    );
    final subStyle = GoogleFonts.pressStart2p(
      fontSize: 14,
      color: const Color(0xff184e77),
    );

    return Container(
      alignment: const Alignment(0, -0.15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: titleStyle)
              .animate()
              .slideY(duration: 750.ms, begin: -3, end: 0),
          const SizedBox(height: 24),
          Text(subtitle, style: subStyle)
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 1.seconds)
              .then()
              .fadeOut(duration: 1.seconds),
        ],
      ),
    );
  }
}
```

---

## 16. lib/src/widgets/game_app.dart

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../flappy_bird.dart';
import 'score_card.dart';
import 'overlay_screen.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  // build の外で生成（毎フレーム再生成を防ぐ）
  late final FlappyBird _game = FlappyBird();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xff87CEEB),
        body: SafeArea(
          child: Column(
            children: [
              ScoreCard(score: _game.score),
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: SizedBox(
                      width: 400,
                      height: 700,
                      child: GameWidget(
                        game: _game,
                        overlayBuilderMap: {
                          PlayState.welcome.name: (_, __) =>
                              const OverlayScreen(
                                title: 'FLAPPY BIRD',
                                subtitle: 'TAP TO START',
                              ),
                          PlayState.gameOver.name: (_, __) =>
                              const OverlayScreen(
                                title: 'GAME OVER',
                                subtitle: 'TAP TO RETRY',
                              ),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 17. lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'src/widgets/game_app.dart';

void main() {
  runApp(const GameApp());
}
```

---

## 18. コンポーネント依存関係図

```
FlameGame (FlappyBird)
├── score: ValueNotifier<int>          ← ScoreCard が購読
├── playState: PlayState               ← overlays.add/remove を制御
└── World (FlappyWorld)
    ├── [TapCallbacks]                 ← タップ → _startGame() or bird.flap()
    ├── Background                     ← 背景（差し替え可）
    ├── Ground                         ← 地面タイル × 2（無限ループ）
    │   └── GroundTile × 2            ← RectangleHitbox 付き（衝突対象）
    ├── Bird                           ← 鳥（gravity・flap・角度演出）
    │   └── CircleHitbox              ← PipePair / GroundTile と衝突
    └── PipePair × n                  ← JSON から spawnX/gapCenterY を受け取る
        ├── 上 RectangleComponent     ← RectangleHitbox 付き
        └── 下 RectangleComponent     ← RectangleHitbox 付き
```

```
Flutter Widget ツリー
GameApp (StatefulWidget)
└── MaterialApp
    └── Scaffold
        ├── ScoreCard                  ← ValueListenableBuilder
        └── GameWidget(game: _game)
            └── overlayBuilderMap
                ├── "welcome"  → OverlayScreen
                └── "gameOver" → OverlayScreen
```

---

## 19. ゲームループ・状態遷移

```
[welcome]
    │ タップ
    ▼
[playing]
    │ Bird が PipePair/GroundTile に衝突
    ▼
[gameOver]
    │ タップ
    ▼
[playing] ← _startGame() で全コンポーネントをリセット
```

---

## 20. パイプ出現ロジック詳細

```
_traveledX += pipeSpeed * dt   （毎フレーム積算）

_pendingPipes（spawnX 昇順のキュー）
    先頭の spawnX <= _traveledX になったら PipePair を add()
    → removeAt(0) でキューから除去
    → 次のパイプも同フレームで条件を満たせば連続 add()

PipePair.update(dt)
    position.x -= speed * dt
    position.x + pipeWidth < birdX かつ未採点 → score++
    position.x < -pipeWidth * 2 → removeFromParent()
```

---

## 21. 実装ステップ（推奨順）

1. `flutter create flappy_bird --empty` でプロジェクト作成
2. `pubspec.yaml` を本仕様書の通りに書き換え
3. `assets/data/pipes.json` を配置
4. `config.dart` 作成
5. `pipe_data.dart` / `pipe_loader.dart` 作成
6. `FlappyBird`（FlameGame）骨格作成・黒画面確認
7. `FlappyWorld`（World + TapCallbacks）作成
8. `Background` / `Ground` 追加・表示確認
9. `Bird` 追加・重力・フラップ動作確認
10. `HasCollisionDetection` を FlappyBird に追加（`with HasCollisionDetection`）
11. `PipePair` 追加・JSON ロード・出現確認
12. 衝突 → gameOver 遷移確認
13. スコア加算確認
14. Flutter UI レイヤー（ScoreCard / OverlayScreen / flutter_animate）
15. `flutter run -d chrome --web-renderer canvaskit` で Web 動作確認

---

## 22. 既知の注意点・落とし穴

| 項目 | 内容 |
|---|---|
| ホットリロード | Flame は Flutter のホットリロード非対応。変更後は `r` ではなく `R`（フルリスタート）を使う |
| コンポーネント削除タイミング | `removeFromParent()` はキューイング処理。削除直後の `children.query<>()` には削除前の状態が残る |
| `HasCollisionDetection` | `FlappyBird extends FlameGame with HasCollisionDetection` に追加を忘れずに |
| Web サウンド | Autoplay Policy により初回ユーザー操作前に音を鳴らせない。`flame_audio` は初回タップ後に初期化すること |
| `gapCenterY` 範囲外 | debug ビルドでは `assert` が機能する。JSON 編集時は有効範囲を確認すること |
| Vector2 精度 | Flame 1.20+ で Vector2 が 32bit 化済み。高精度計算が必要な場合は `double` 変数で別途保持すること |
