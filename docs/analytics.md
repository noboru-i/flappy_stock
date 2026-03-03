# Google Analytics 設計

Firebase Analytics を利用し、ゲームプレイの行動データを収集します。

## 実装

`lib/src/services/analytics_service.dart` の `AnalyticsService` シングルトン経由でイベントを送信します。

```dart
AnalyticsService.instance.logSelectStage(stage.id, stage.name);
```

---

## イベント一覧

### `screen_view`（自動ログ）

画面遷移のたびに記録されます。

| パラメータ | 値の例 |
|---|---|
| `screen_name` | `welcome` / `stageSelect` / `playing` / `clear` / `gameOver` |

送信タイミング: `FlappyStock.playState` セッターの呼び出し時。

---

### `select_stage`

ステージ選択リストからステージをタップしたとき。

| パラメータ | 型 | 説明 |
|---|---|---|
| `stage_id` | `string` | ステージID（例: `5255_daily`） |
| `stage_name` | `string` | ステージ表示名（例: `5255 Daily`） |

送信タイミング: `FlappyWorld.startGame()` の呼び出し時。

---

### `stage_clear`

ステージ内の全ローソク足を通過し、クリア状態に遷移したとき。

| パラメータ | 型 | 説明 |
|---|---|---|
| `stage_id` | `string` | ステージID |
| `final_value` | `int` | クリア時の評価額（株価 × 株数 + 現金、整数に丸め） |

送信タイミング: `FlappyWorld._onCandleScored()` 内で全ローソク足スコア済み判定後。

---

### `login`（Firebase 標準イベント）

Google サインインが成功したとき。

| パラメータ | 値 |
|---|---|
| `method` | `google` |

送信タイミング: `AuthService.signInWithGoogle()` の正常完了後。

---

## Firebase コンソールでの確認

1. [Firebase コンソール](https://console.firebase.google.com/) → プロジェクト `flappy-stock-prod` を選択
2. 左メニュー「Analytics」→「Events」でイベント一覧を確認
3. デバッグ時は「DebugView」を使用（`firebase_analytics` の `setAnalyticsCollectionEnabled` を参照）
