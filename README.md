# Flappy Stock

Flutter + Flame で作った Flappy Bird ライクなゲーム。実際の株価ローソク足チャートを障害物として飛び抜けながら、株の売買で資産を増やすことを目指す。

## 技術スタック

| 項目 | 内容 |
|---|---|
| フレームワーク | Flutter (Web ターゲット) |
| ゲームエンジン | Flame ^1.28.1 |
| レンダラー | CanvasKit |
| 言語 | Dart |
| バックエンド | Firebase (Hosting / Firestore / Analytics) |

## コマンド

| コマンド | 内容 |
|---|---|
| `make run` | Chrome で開発サーバーを起動 |
| `make build` | Web 向けリリースビルド |
| `make deploy` | ビルド → Firebase Hosting にデプロイ |
| `make deploy-firestore` | Firestore セキュリティルール・インデックスをデプロイ |

```bash
make run               # 開発
make build             # ビルドのみ
make deploy            # ビルド + デプロイ
make deploy-firestore  # Firestore ルール・インデックスのみデプロイ
```

## ゲームの遊び方

### 基本操作
- **画面タップ / クリック**で鳥が上昇する（長押しするほど上昇力が増す）
- **キーボード `A` / `S` / `D`** キーを押しながら飛ぶことで取引モードを切り替えられる

### ゲームの目的
ステージ内の全ローソク足を通過し、最終的な**評価額（株 × 最終価格 + 現金）**を最大化することが目標。

### 取引システム
- ローソク足の右端を通過した瞬間に取引が実行される
- 鳥がローソク足のヒゲ範囲内（`low` ≤ 鳥の高さ ≤ `high`）にいるときのみ、その高さが**約定価格**として使われる
- ヒゲ範囲外を通過した場合は取引されない

| モード | キー | 動作 |
|---|---|---|
| 売り（Sell） | `S` | 保有株を全て売却して現金化 |
| 買い（Buy） | `A` | 現金を全て使って株を購入 |
| 空売り（Short） | `D` | 空売りポジションを建てる（次のローソク足で自動決済） |

初期状態: 株 **100株** 保有・現金 **0円**

### ゲーム終了
- 地面や天井に当たってもゲームオーバーにはならない（クランプされる）
- 最後のローソク足を通過すると**クリア**。評価額とランキングが表示される

## ドキュメント

- データJSON仕様: [docs/data_json_format.md](docs/data_json_format.md)
- Firestore データベース設計: [docs/firestore.md](docs/firestore.md)
- Google Analytics 設計: [docs/analytics.md](docs/analytics.md)
