# Flappy Stock — Claude Code 実装ガイド

## 概要

Flappy Stock は Flutter + Flame で作られた Flappy Bird 風ゲームで、障害物として実際の株価ローソク足チャートを使用します。鳥は J-Quants API から取得したローソク足の間を飛び抜けます。ステージ内の全ローソク足を通過することが目標で、スコアは通過時の鳥の Y 座標がローソク足の価格帯にどれだけ近いかで決まります。

## ディレクトリ構成

```
lib/
├── main.dart                         # エントリーポイント — runApp(GameApp())
└── src/
    ├── flappy_stock.dart             # FlameGame (HasCollisionDetection + KeyboardEvents)
    ├── flappy_world.dart             # World (TapCallbacks, ローソク足管理, カメラ)
    ├── config.dart                   # 全定数 (寸法, 物理)
    ├── data/
    │   ├── pipe_data.dart            # CandleData / StageData モデル
    │   └── pipe_loader.dart          # JSON アセットローダー + spawnX 正規化
    ├── components/
    │   ├── components.dart           # 全コンポーネントのバレルエクスポート
    │   ├── bird.dart                 # Bird (CircleComponent + CollisionCallbacks)
    │   ├── candle.dart               # Candle 障害物 (PositionComponent, OHLC 描画)
    │   ├── ground.dart               # Ground + GroundTile (タイリング, ヒットボックス)
    │   └── background.dart           # 株価チャート風グリッド背景
    └── widgets/
        ├── game_app.dart             # Flutter MaterialApp ラッパー, オーバーレイマップ
        ├── score_card.dart           # スコア表示 (ValueNotifier 駆動)
        ├── overlay_screen.dart       # Welcome / Game Over / Clear UI
        └── stage_select_screen.dart  # ステージ選択リスト

assets/data/pipes/   # ステージ JSON ファイル (ローソク足データ)
  ├── stage_01.json  # チュートリアル (手作業座標)
  ├── stage_02.json  # チュートリアル ステージ2
  ├── 5255_daily.json   # 実株価データ (spawnX は Unix タイムスタンプ, 実行時スケーリング)
  ├── 5255_weekly.json
  └── 5255_monthly.json

packages/jquants_client/  # 独立 Dart パッケージ — 株価データ取得
  ├── lib/jquants/
  │   ├── jquants_auth.dart         # API キー認証
  │   ├── jquants_client.dart       # J-Quants API v2 用 HTTP クライアント
  │   ├── jquants_service.dart      # 高レベルサービス (取得 + リサンプル)
  │   ├── ohlcv_model.dart          # OhlcvData モデル
  │   └── ohlcv_resampler.dart      # 日足 → 週足/月足 リサンプル
  ├── bin/
  │   ├── jquants_client.dart       # CLI: 株価取得 → output/{code}/{period}.json
  │   └── convert_to_stage.dart     # CLI: output/ → assets/data/pipes/*.json に変換
  └── output/                       # 取得した生データ (assets/ には直接コミットしない)
```

## ステートマシン

```
[welcome] ──タップ/スペース──> [stageSelect] ──ステージ選択──> [playing]
                                                                   │
                                                       全ローソク足通過
                                                                   │
[gameOver] <── (予約済み, 未実装) ──>                           [clear]
    └──タップ/スペース──> [stageSelect]                 └──タップ/スペース──> [stageSelect]
```

`FlappyStock.playState` セッターが各ステートに応じて `overlays.add/remove` を自動管理します。各ステート名は `GameApp` の `overlayBuilderMap` のエントリに対応します。

## 座標系

2 つの座標系が使われています — ローソク足や背景の描画を編集する際には理解が必須です：

| 系 | 原点 | Y の向き | 用途 |
|---|---|---|---|
| **JSON** | 表示エリア左下 | 上が正 | `CandleData` フィールド: `high`, `low`, `open`, `close` |
| **Flame** | 左上 | 下が正 | 全 `PositionComponent` の座標 |

変換式（`Candle.render` 内で適用）：
```dart
flameY = stageHeight - jsonY * 3   // *3 は stageHeight = 表示高さ * 3 のため
jsonY  = (stageHeight - flameY) / 3
```

JSON Y 座標の有効範囲: `0 <= low <= open/close <= high <= stageHeight / 3`
（現在の設定で `stageHeight / 3` ≈ 616 ゲーム単位）

## 主要定数 (`lib/src/config.dart`)

| 定数 | 値 | 説明 |
|---|---|---|
| `gameWidth` | 400.0 | 固定キャンバス幅 |
| `gameHeight` | 700.0 | 固定ビューポート高さ |
| `stageHeight` | `(gameHeight - groundHeight) * 3` | スクロール可能な全ステージ高さ |
| `groundHeight` | `gameHeight * 0.12` | 地面バーの高さ |
| `pipeWidth` | `gameWidth * 0.10` | 各ローソク足の幅 |
| `pipeSpeed` | `gameWidth * 0.55` | デフォルトスクロール速度 (ステージで上書き可) |
| `birdRadius` | `gameWidth * 0.07` | 鳥の当たり判定半径 |
| `gravity` | `gameHeight * 1.25` | 下向き加速度 |
| `maxFlapHoldTime` | 0.5秒 | 最大長押し時間 |

## ゲームメカニクス

### 鳥の物理
- タップ/スペース長押し → 押し続けた時間の2乗に比例して上昇加速度が増加
- 離す → 重力が働く
- Y=0（天井）〜Y=stageHeight（地面）でクランプ：速度ゼロにリセット、ゲームオーバーなし
- 傾き角度は垂直速度に比例

### ローソク足スコアリング
- 各ローソク足の右端が鳥の X 座標（`gameWidth * 0.25`）を通過した時点でスコア加算
- スコア値 = `jsonY.round()`（JSON 座標での鳥の Y 値）、鳥がウィック範囲内（`low <= jsonY <= high`）の場合のみ加算
- `Candle` の `onScored` コールバック → `FlappyWorld._onCandleScored()` → 全ローソク足通過後に `PlayState.clear` へ遷移

### ローソク足スポーン
- `FlappyWorld._traveledX` がフレームごとに `pipeSpeed * dt` を累積
- `_traveledX >= _pendingCandles.first.spawnX` になると `Candle` を生成してワールドに追加
- ローソク足は `pipeSpeed` で左にスクロール; `position.x < -pipeWidth * 2` で削除

### カメラ追従
- カメラが鳥の Y 座標を追いかける（縦スクロールステージ）
- `viewfinder.position.y` はステージ外を表示しないようにクランプ

## ステージ JSON フォーマット

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

- **`spawnX`**: チュートリアルステージではゲーム座標値（移動ピクセル数）。実株価ステージ（例: `5255_daily`）では Unix タイムスタンプ（秒）— `PipeLoader` が自動検出して正規化。
- **`pipeSpeed`**: ステージごとのスクロール速度。グローバルデフォルト定数を上書き。
- **OHLC 値**: JSON 座標系（底辺=0）。`PipeLoader` がロード時に `assert` で OHLC 整合性を検証。

### spawnX 正規化 (`PipeLoader._normalizeSpawnX`)
ローソク足間の平均間隔が `_rawDataThreshold`（10,000 単位）を超える場合、Unix タイムスタンプ等の生データと判断して以下のようにスケーリング:
- 先頭ローソク足が `_targetFirstSpawnX`（600px 移動後）に出現
- 平均間隔が `_targetInterval`（450px）になるよう調整

## Flame API 規約

- `TapCallbacks` → `FlappyWorld`（`World` サブクラス）にミックスイン、`FlameGame` には**付けない**
- `KeyboardEvents` → `FlappyStock`（`FlameGame` サブクラス）にミックスイン; スペースバー処理
- `HasCollisionDetection` → `FlappyStock`（FlameGame）に付与; ヒットボックス検出に必須
- `HasGameReference<FlappyStock>` → ゲーム状態が必要な全コンポーネントに付与; `.game` でアクセス
- `GroundTile`: `RectangleComponent` を継承し、`onLoad` 内で `RectangleHitbox()` を追加（コンストラクタの競合により `with RectangleHitbox` は使用不可）
- `Bird` は `CollisionCallbacks` と `CircleHitbox(radius: 1)` を持つ — 衝突トリガーのゲームオーバー基盤は存在するが未実装

## 開発ワークフロー

```bash
# Chrome で実行（主要ターゲット）
make run          # flutter run -d chrome

# 本番ビルド
make build        # flutter build web --release

# Firebase Hosting にデプロイ
make deploy       # build + firebase deploy --only hosting
```

**Flame はホットリロード非対応** — コード変更後は Flutter CLI で `r`（ホットリロード）ではなく `R`（フルリスタート）を使う。

## CI/CD

- `main` にプッシュ → GitHub Actions が `make build` を実行し Firebase Hosting プロジェクト `flappy-stock-prod` にデプロイ
- 必要なシークレット: `FIREBASE_SERVICE_ACCOUNT_FLAPPY_STOCK_PROD`

## 実株価データの追加

1. `packages/jquants_client` で `JQUANTS_API_KEY` 環境変数を設定（または認証に渡す）
2. 取得 CLI を実行:
   ```bash
   cd packages/jquants_client
   dart run bin/jquants_client.dart  # output/{code}/{period}.json に取得
   ```
3. ステージ形式に変換:
   ```bash
   dart run bin/convert_to_stage.dart  # ../../assets/data/pipes/ に書き出し
   ```
4. 新しい JSON ファイルは実行時に自動検出される — コード変更不要

## 新ステージの手動追加

1. 上記のステージ JSON フォーマットに従って `assets/data/pipes/my_stage.json` を作成
2. JSON Y 座標を使用（底辺=0, 最大値 ≈ 616）
3. `PipeLoader` が自動ロード（`AssetManifest` から `assets/data/pipes/*.json` を全て読み込む）
4. コード変更不要 — `StageSelectScreen` に自動で表示される

## 実装メモ

### 衝突 / 地面
- GroundTile のヒットボックスは存在するが `Bird.onCollisionStart` が未オーバーライド → 衝突トリガーのゲームオーバーは現在なし
- 地面/天井の境界は `Bird.update` での Y 座標クランプで対応

### コンポーネント削除のタイミング
- `removeFromParent()` はキュー処理: 今フレームで削除されたコンポーネントは次フレームまで `children.query<>()` に残る可能性あり

### ローソク足描画の座標計算
```dart
final flameHigh  = stageHeight - high  * 3;   // JSON 上端 → Flame 上端
final flameLow   = stageHeight - low   * 3;   // JSON 下端 → Flame 下端
final bodyTop    = min(flameOpen, flameClose); // Flame 座標でのボディ上端
final bodyBottom = max(flameOpen, flameClose);
```

陽線はティール色（`0xFF26A69A`）、陰線は赤（`0xFFEF5350`）。

### 背景グリッド
- 水平グリッド線は JSON Y 座標 50 単位ごと、右端に価格ラベル
- 垂直グリッド線は `game.pipeScrollOffset % gridIntervalX` に同期してスクロール

### 依存パッケージ
| パッケージ | バージョン | 用途 |
|---|---|---|
| `flame` | ^1.28.1 | ゲームエンジン |
| `flutter_animate` | ^4.5.2 | オーバーレイのアニメーション |
| `google_fonts` | ^8.0.2 | Press Start 2P フォント (UI 用) |
