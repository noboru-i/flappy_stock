# Flappy Stock — Claude Code 実装ガイド

## 概要

Flappy Stock は Flutter + Flame で作られた Flappy Bird 風ゲームで、障害物として実際の株価ローソク足チャートを使用します。鳥は J-Quants API から取得したローソク足の間を飛び抜けます。ローソク足のヒゲ範囲内を通過すると取引が実行され、最終的な保有ポートフォリオの評価額がスコアになります。

## ディレクトリ構成

```
lib/
├── main.dart
└── src/
    ├── flappy_stock.dart             # FlameGame (HasCollisionDetection + KeyboardEvents)
    ├── flappy_world.dart             # World (ローソク足管理, カメラ, ニュース ticker)
    ├── config.dart                   # 全定数 (寸法, 物理, 取引)
    ├── data/
    │   ├── pipe_data.dart            # CandleData / StageData モデル
    │   ├── pipe_loader.dart          # JSON アセットローダー + spawnX/Y スケール正規化
    │   ├── news_data.dart            # NewsData モデル
    │   └── news_loader.dart          # ニュース JSON ローダー
    ├── components/
    │   ├── components.dart           # バレルエクスポート
    │   ├── bird.dart                 # Bird (CircleComponent + CollisionCallbacks)
    │   ├── candle.dart               # Candle 障害物 (PositionComponent, OHLC 描画)
    │   ├── ground.dart               # Ground + GroundTile (タイリング, ヒットボックス)
    │   ├── background.dart           # 株価チャート風グリッド背景
    │   ├── minimap.dart              # MinimapComponent (viewport に追加)
    │   └── score_popup.dart          # ScorePopup (取引時にフロートするテキスト)
    ├── services/
    │   ├── auth_service.dart         # Firebase Auth (Google Sign-In, @monstar-lab.com 限定)
    │   ├── ranking_service.dart      # Firestore ランキング
    │   ├── analytics_service.dart    # Firebase Analytics
    │   └── tutorial_service.dart     # SharedPreferences でチュートリアル表示済みフラグ管理
    └── widgets/
        ├── game_app.dart             # MaterialApp ラッパー, overlay マップ, BottomBar
        ├── playing_overlay.dart      # プレイ中 HUD (株数/現金/空売り表示 + 取引ボタン + ニュース)
        ├── overlay_screen.dart       # Welcome / Game Over / Clear UI
        ├── stage_select_screen.dart  # ステージ選択リスト
        ├── ranking_list.dart         # ステージ別ランキング (Firestore リアルタイム)
        └── tutorial_screen.dart      # チュートリアル画面 (初回起動時に表示)

assets/data/pipes/    # → フォーマット詳細: docs/data_json_format.md
  ├── 5255_daily.json
  ├── 5255_weekly.json
  └── 5255_monthly.json

assets/data/news/     # → フォーマット詳細: docs/data_json_format.md
  ├── 5255_daily.json
  ├── 5255_weekly.json
  └── 5255_monthly.json

packages/jquants_client/  # 独立 Dart パッケージ — 株価データ取得
  ├── lib/jquants/
  ├── bin/
  │   ├── jquants_client.dart       # CLI: 株価取得 → output/{code}/{period}.json
  │   └── convert_to_stage.dart     # CLI: output/ → assets/data/pipes/*.json に変換
  └── output/                       # 取得した生データ (assets/ には直接コミットしない)

docs/
  ├── data_json_format.md           # pipes / news JSON スキーマ
  ├── firestore.md                  # Firestore コレクション設計・セキュリティルール
  └── analytics.md                  # Firebase Analytics イベント一覧
```

## ステートマシン

```
[welcome] ──タップ──> [stageSelect] ──ステージ選択──> [playing]
                                                          │
                                              全ローソク足通過
                                                          │
[gameOver] <── (予約済み, 未実装) ──>                  [clear]
    └──タップ──> [stageSelect]               └──タップ──> [stageSelect]
```

`FlappyStock.playState` セッターが各ステートに応じて `overlays.add/remove` を自動管理します。

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
| `flapLiftBase` | `gravity * 2.0` | フラップ開始時の上昇加速度 |
| `flapLiftExtra` | `gravity * 1.3` | 最大長押し時の追加上昇加速度 |
| `maxFlapHoldTime` | 0.5秒 | 最大長押し時間 |
| `initialShares` | 100.0 | ゲーム開始時の保有株数 |
| `shortSellShares` | 100.0 | 空売り1回あたりの株数 |

## ゲームメカニクス

### 鳥の物理
- フラップ（ボタン長押し）→ 押し続けた時間の2乗に比例して上昇加速度が増加
- 離す → 重力が働く
- Y=0（天井）〜Y=stageHeight（地面）でクランプ：速度ゼロにリセット、ゲームオーバーなし
- 傾き角度は垂直速度に比例

### 取引システム（スコアリング）
ゲーム開始時に `initialShares = 100株` を保有し、現金 = 0 円から始まる。

各ローソク足の右端が鳥の X 座標（`gameWidth * 0.25`）を通過した時点で判定:
- 鳥がウィック範囲内（`low <= jsonY <= high`）の場合のみ取引実行
- 空売りポジション保有中は自動決済（他の取引は行わない）
- それ以外は `tradeMode` に応じて実行：
  - **sell**: 全株を現在価格で売却（株 → 現金）
  - **buy**: 全現金で株を購入（現金 → 株）
  - **short**: `shortSellShares` 株を空売り（後のローソク足で自動決済）

**最終スコア** = `shares * finalPrice + cash`
- `finalPrice`: 最終ローソク足通過時の jsonY（範囲内の場合）または close（範囲外の場合）
- 空売りポジションが残っていれば finalPrice で強制決済

### 操作（PlayingOverlay ボタン / キーボード）
- **現物買い (A)**: 現金がある場合のみ有効
- **現物売り (S)**: 株を保有している場合のみ有効
- **空売り (D)**: ポジション未保有の場合のみ有効
- ボタン押下 → tradeMode 切替 + flapStart
- ボタン離す → flapEnd
- キーボード: 同様に A/S/D キーに対応（`FlappyStock.onKeyEvent`）

### ニュース Ticker
- `assets/data/news/{stageId}.json` を `NewsLoader` がロード
- ローソク足の日付（xLabel）を基準に spawnX を線形補間
- ローソク足が画面右端に入ったタイミングでバブル出現、左端を超えると消える
- `FlappyStock.newsTickerBubbles` ValueNotifier → `PlayingOverlay._NewsTicker` で表示

### ローソク足スポーン
- `FlappyWorld._traveledX` がフレームごとに `pipeSpeed * dt` を累積
- `_traveledX >= _pendingCandles.first.spawnX` になると `Candle` を生成してワールドに追加
- ローソク足は `pipeSpeed` で左にスクロール; `position.x < -pipeWidth * 2` で削除

### カメラ追従
- カメラが鳥の Y 座標を追いかける（縦スクロールステージ）
- `viewfinder.position.y` はステージ外を表示しないようにクランプ

## データ JSON フォーマット

→ 詳細は [`docs/data_json_format.md`](docs/data_json_format.md)

### spawnX 正規化 (`PipeLoader._normalizeSpawnX`)
ローソク足間の平均間隔が `_rawDataThreshold`（10,000 単位）を超える場合、Unix タイムスタンプ等の生データと判断してスケーリング:
- 先頭ローソク足が `_targetFirstSpawnX`（600px 移動後）に出現
- 平均間隔が `_targetInterval`（450px）になるよう調整
- スケーリング後に `xLabel`（日付文字列）を自動付与

### Y スケール正規化 (`PipeLoader._normalizeYScale`)
ステージ内全ローソク足の high/low 範囲 + 15% マージンを `StageData.yMin/yMax` にセット。
MinimapComponent と背景描画がこの値を使って表示範囲を決定する。

## Flame API 規約

- `TapCallbacks` → **使用なし**（フラップ操作は Flutter ウィジェット `PlayingOverlay` が担当）
- `KeyboardEvents` → `FlappyStock`（`FlameGame` サブクラス）にミックスイン; A/S/D キー処理
- `HasCollisionDetection` → `FlappyStock`（FlameGame）に付与; ヒットボックス検出に必須
- `HasGameReference<FlappyStock>` → ゲーム状態が必要な全コンポーネントに付与; `.game` でアクセス
- `MinimapComponent` → `camera.viewport.add(MinimapComponent())` で FlappyStock.onLoad に登録
- `GroundTile`: `RectangleComponent` を継承し、`onLoad` 内で `RectangleHitbox()` を追加（コンストラクタの競合により `with RectangleHitbox` は使用不可）
- `Bird` は `CollisionCallbacks` と `CircleHitbox(radius: 1)` を持つ — 衝突トリガーのゲームオーバー基盤は存在するが未実装

## 認証・ランキング・Analytics

- 認証: `@monstar-lab.com` ドメインの Google アカウントのみ許可。未サインインでもゲームはプレイ可能。
- Firestore ランキング: → [`docs/firestore.md`](docs/firestore.md)
- Analytics イベント: → [`docs/analytics.md`](docs/analytics.md)

## 開発ワークフロー

```bash
# Chrome で実行（主要ターゲット）
make run          # flutter run -d chrome

# 本番ビルド
make build        # flutter build web --release

# Firebase Hosting にデプロイ
make deploy       # build + firebase deploy --only hosting

# Firestore ルール・インデックスをデプロイ
make deploy-firestore
```

**Flame はホットリロード非対応** — コード変更後は Flutter CLI で `r`（ホットリロード）ではなく `R`（フルリスタート）を使う。

## CI/CD

- `main` にプッシュ → GitHub Actions が `make build` を実行し Firebase Hosting プロジェクト `flappy-stock-prod` にデプロイ
- 必要なシークレット: `FIREBASE_SERVICE_ACCOUNT_FLAPPY_STOCK_PROD`

## 実株価データの追加

1. `packages/jquants_client` で `JQUANTS_API_KEY` 環境変数を設定
2. 取得 CLI を実行:
   ```bash
   cd packages/jquants_client
   dart run bin/jquants_client.dart  # output/{code}/{period}.json に取得
   ```
3. ステージ形式に変換:
   ```bash
   dart run bin/convert_to_stage.dart  # ../../assets/data/pipes/ に書き出し
   ```
4. 必要に応じて `assets/data/news/{stageId}.json` を作成（フォーマットは `docs/data_json_format.md`）
5. 新しい JSON ファイルは実行時に自動検出される — コード変更不要

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
- 水平グリッド線は JSON Y 座標 50 単位ごと、右端に価格ラベル（`stageYMin/yMax` に基づく）
- 垂直グリッド線は `game.pipeScrollOffset % gridIntervalX` に同期してスクロール

### 依存パッケージ
| パッケージ | バージョン | 用途 |
|---|---|---|
| `flame` | ^1.35.1 | ゲームエンジン |
| `flutter_animate` | ^4.5.2 | オーバーレイのアニメーション |
| `google_fonts` | ^8.0.2 | Press Start 2P フォント (UI 用) |
| `firebase_core` | ^4.5.0 | Firebase 初期化 |
| `firebase_analytics` | ^12.1.3 | Analytics |
| `firebase_auth` | ^6.2.0 | Google Sign-In |
| `google_sign_in` | ^7.2.0 | Google Sign-In (non-web) |
| `cloud_firestore` | ^6.1.3 | ランキング DB |
| `shared_preferences` | ^2.5.4 | チュートリアル表示済みフラグ |
