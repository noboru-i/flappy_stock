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
| `read` | 認証済み + メール確認済み + `@monstar-lab.com` ドメイン |
| `create` | `read` の条件 + `uid` フィールドが自分の UID と一致 |
| `update` / `delete` | 不可 |

### ドメイン制限の補足

- Firestore ルールで `request.auth.token.email` と `email_verified` を検証し、`@monstar-lab.com` のみ許可。
- この制限はデータアクセス層の制御です（サインイン自体の拒否は Firebase Auth Blocking Functions 側で実施可能）。

## インデックス

ファイル: `firestore.indexes.json`

| コレクション | フィールド | 用途 |
|---|---|---|
| `scores` | `stageId ASC`, `finalValue DESC` | ステージ別ランキング取得 |

## デプロイ

```bash
make deploy-firestore
```
