# Flappy Stock

Flutter + Flame で作った Flappy Bird ライクなゲーム。株価チャートをモチーフにしたパイプを避けながらスコアを伸ばす。

## 技術スタック

| 項目 | 内容 |
|---|---|
| フレームワーク | Flutter (Web ターゲット) |
| ゲームエンジン | Flame ^1.28.1 |
| レンダラー | CanvasKit |
| 言語 | Dart |

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

- 画面をタップ（クリック）すると鳥が羽ばたく
- パイプと地面を避けてスコアを稼ぐ
- ぶつかったらゲームオーバー。再タップでリトライ
