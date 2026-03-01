# Firestore データベース設計

## コレクション構造

### `scores`

ステージクリア時に保存されるスコアレコード。

| フィールド | 型 | 説明 |
|---|---|---|
| `uid` | `string` | Firebase Auth UID |
| `displayName` | `string` | ユーザー表示名 |
| `photoURL` | `string?` | プロフィール画像 URL（未設定の場合は null） |
| `stageId` | `string` | ステージ ID（例: `5255_daily`） |
| `finalValue` | `number` | クリア時の評価額（株価 × 株数 + 現金） |
| `createdAt` | `timestamp` | サーバータイムスタンプ |

```
scores/{autoId}
  ├── uid:         "abc123"
  ├── displayName: "Player Name"
  ├── photoURL:    "https://..."
  ├── stageId:     "5255_daily"
  ├── finalValue:  12345.67
  └── createdAt:   Timestamp
```

## セキュリティルール

ファイル: `firestore.rules`

| 操作 | 条件 |
|---|---|
| `read` | 認証済みユーザーのみ |
| `create` | 認証済み かつ `uid` フィールドが自分の UID と一致 |
| `update` / `delete` | 不可 |

## インデックス

ファイル: `firestore.indexes.json`

| コレクション | フィールド | 用途 |
|---|---|---|
| `scores` | `stageId ASC`, `finalValue DESC` | ステージ別ランキング取得 |

## デプロイ

```bash
make deploy-firestore
```
