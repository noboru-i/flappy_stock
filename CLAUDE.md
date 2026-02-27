# Flappy Stock — Claude Code 向け実装メモ

## ディレクトリ構成

```
lib/
├── main.dart
└── src/
    ├── flappy_stock.dart     # FlameGame（HasCollisionDetection 付き）
    ├── flappy_world.dart     # World（TapCallbacks・パイプ管理）
    ├── config.dart           # 全定数
    ├── data/
    │   ├── pipe_data.dart    # StageData / PipeData モデル
    │   └── pipe_loader.dart  # JSON ローダー
    ├── components/
    │   ├── components.dart   # barrel export
    │   ├── bird.dart
    │   ├── pipe_pair.dart
    │   ├── ground.dart
    │   └── background.dart
    └── widgets/
        ├── game_app.dart         # Flutter ラッパー
        ├── score_card.dart       # ValueNotifier 連携スコア表示
        └── overlay_screen.dart   # ウェルカム / ゲームオーバー UI

assets/data/pipes/  # パイプ配置定義（ステージデータ、stage_XX.json）
```

## 状態遷移

```
[welcome] → タップ → [playing] → 衝突 → [gameOver] → タップ → [playing]
```

`FlappyStock.playState` の setter が `overlays.add/remove` を自動制御する。

## 実装上の注意点

### Flame API
- `TapCallbacks` は `World` サブクラスに mixin する（`FlameGame` には付けない）
- `HasGameReference<FlappyStock>` でゲームインスタンスを参照（`.game` でアクセス）
- `HasCollisionDetection` は `FlappyStock`（FlameGame）に付ける

### 衝突判定
- `GroundTile` は `RectangleComponent` を継承し、`onLoad` で `add(RectangleHitbox())` として追加する
  （`with RectangleHitbox` はコンストラクタ宣言のためミックスイン不可）
- `Bird.onCollisionStart` でパイプ衝突を判定するときは `other.parent is PipePair`
  （パイプの hitbox は `PipePair` の子 `RectangleComponent` に付いているため `other` は `RectangleComponent`）

### パイプ出現ロジック
- `_traveledX` に毎フレーム `pipeSpeed * dt` を積算し、`_pendingPipes` の `spawnX` と比較してパイプを生成
- パイプデータは `assets/data/pipes/` 以下の JSON で管理。各パイプに `gapTop`・`gapBottom` を指定する
  有効範囲：`0 <= gapTop < gapBottom <= gameHeight - groundHeight`

### その他
- Flame はホットリロード非対応。変更後は `R`（フルリスタート）を使う
- `removeFromParent()` はキューイング処理のため、削除直後の `children.query<>()` には削除前の状態が残ることがある
