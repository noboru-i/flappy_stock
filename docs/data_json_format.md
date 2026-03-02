# データ JSON フォーマット仕様

このドキュメントは、以下2種類のアセットJSONフォーマットを定義します。

- `assets/data/news/*.json`（ステージごとのIR/ニュース）
- `assets/data/pipes/*.json`（ステージごとのローソク足）

---

## 1. `assets/data/news/*.json`

### 1-1. ファイル単位の仕様

- ルートは **配列**（`Array<Object>`）
- 1要素が1件のニュース
- ファイル名はステージIDに合わせることを推奨（例: `5255_daily.json`）

### 1-2. ニュース要素の仕様

| キー | 型 | 必須 | 説明 |
|---|---|---|---|
| `date` | `string` | 必須 | 日付。`YYYY-MM-DD` 形式を推奨 |
| `title` | `string` | 必須 | ニュースタイトル |
| `summary` | `string` | 必須 | 要約文 |
| `url` | `string` | 必須 | 遷移先URL（`https://...` 推奨） |

### 1-3. 例

```json
[
  {
    "date": "2025-11-24",
    "title": "マルチAIエージェントを活用したPoC開発プラットフォーム「MonstarX」を提供開始",
    "summary": "独自のAI技術を結集し、企業のAI導入における検証（PoC）を短期間で実現するプラットフォームを市場に投入。",
    "url": "https://monstar-lab.com/jp_ja/news"
  }
]
```

---

## 2. `assets/data/pipes/*.json`

### 2-1. ファイル単位の仕様

- ルートは **オブジェクト**（`Object`）
- 1ファイルが1ステージを表す

| キー | 型 | 必須 | 説明 |
|---|---|---|---|
| `id` | `string` | 必須 | ステージID（例: `5255_daily`） |
| `name` | `string` | 推奨 | 表示名。未指定時は実装側で `id` を利用 |
| `pipeSpeed` | `number` | 必須 | 横スクロール速度 |
| `candles` | `Array<Object>` | 必須 | ローソク足配列 |

### 2-2. `candles` 要素の仕様

| キー | 型 | 必須 | 説明 |
|---|---|---|---|
| `spawnX` | `number` | 必須 | 出現位置。ゲーム座標値またはUnix時刻（秒） |
| `high` | `number` | 必須 | 高値（JSON座標） |
| `low` | `number` | 必須 | 安値（JSON座標） |
| `open` | `number` | 必須 | 始値（JSON座標） |
| `close` | `number` | 必須 | 終値（JSON座標） |
| `xLabel` | `string \| null` | 任意 | X軸ラベル。通常は実行時に自動生成 |

### 2-3. 値の制約

- OHLC整合性（必須）
  - `high >= low`
  - `low <= min(open, close)`
  - `max(open, close) <= high`
- `spawnX`
  - チュートリアル等: ゲーム座標（移動距離）を直接指定
  - 株価生データ: Unix時刻（秒）を指定可能
  - 実行時に `PipeLoader` が必要に応じて正規化（先頭位置と間隔をゲーム向けにスケーリング）

### 2-4. 座標系（重要）

`high/low/open/close` は **JSON座標**（画面下端=0、上方向が正）で管理します。
描画時は Flame 座標（左上原点、下方向が正）へ変換されます。

### 2-5. 例

```json
{
  "id": "5255_daily",
  "name": "5255 Daily",
  "pipeSpeed": 150.0,
  "candles": [
    {
      "spawnX": 1763478000,
      "high": 210.0,
      "low": 186.0,
      "open": 207.0,
      "close": 189.0
    }
  ]
}
```
