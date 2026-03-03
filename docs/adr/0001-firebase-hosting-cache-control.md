# ADR-0001: Firebase Hosting キャッシュ制御戦略

## ステータス

承認済み (2026-03-04)

## コンテキスト

Flutter Web アプリを Firebase Hosting で配信するにあたり、以下の制約・背景がある。

- Flutter のビルド成果物には、コンテンツハッシュ付きのファイル（フォント等）と、ビルドごとに内容が変わるが**ファイル名が固定**のファイル（`main.dart.js` 等）が混在する
- Flutter の Service Worker（`flutter_service_worker.js`）は非推奨となり、現在の実装はインストール後に自己解体（`self.registration.unregister()`）する空実装になっている
  - 参考: `flutter_bootstrap.js` 内のコメント「Flutter's service worker is deprecated and will be removed in a future Flutter release.」
- Service Worker によるプリキャッシュが機能しないため、**HTTP キャッシュが唯一のキャッシュ機構**である
- Firebase Hosting の `headers` ルールは複数マッチした場合、**後勝ち（last match wins）** でヘッダーがマージされる

## 決定

`firebase.json` の `headers` を以下の方針で設定する。

### ルール順序

```json
"headers": [
  // ① 広いルール（先）: ハッシュ付きアセットは長期キャッシュ
  { "source": "**/*.@(js|css|wasm)", "Cache-Control": "public, max-age=31536000, immutable" },

  // ② HTML・JSON は常に最新を確認
  { "source": "**/*.@(html|json)", "Cache-Control": "no-cache" },

  // ③ 特定ルール（後）: Flutter コアファイルは①を上書きして no-cache
  { "source": "/@(flutter_bootstrap|flutter|main.dart|flutter_service_worker).js", "Cache-Control": "no-cache" }
]
```

### `no-cache` を採用した理由（`no-store` は使わない）

| ディレクティブ | 挙動 |
|---|---|
| `no-cache` | キャッシュを保存し、使用前にサーバーへ問い合わせ。変更なしなら **304** で応答（高速） |
| `no-store` | キャッシュを保存しない → 毎回フルダウンロード（非効率） |

`no-store` では Etag / 304 の恩恵が得られないため `no-cache` のみを採用する。

### `main.dart.js` を `immutable` にしない理由

- `flutter build web` は `main.dart.js` のファイル名にコンテンツハッシュを付与しない
- ファイル名が固定のまま内容が変わるため `immutable` を設定すると、デプロイ後も古い JS がキャッシュされ続ける
- 旧来は Service Worker がプリキャッシュを更新することで問題なかったが、SW が非推奨になった現在は HTTP キャッシュの `no-cache` で制御する必要がある

## 採用しなかった代替案

### ファイル名ハッシュ化スクリプト

ビルド後スクリプトで `main.dart.js` をコンテンツハッシュ付きにリネームし `immutable` を設定する手法。
→ Flutter SDK のアップデートに追従するスクリプト保守コストが高く、今回は採用しない。

### `no-cache, no-store, must-revalidate`（変更前の設定）

以前は `no-store` を含む設定だったが、304 応答が活用できず毎回フルダウンロードになっていたため廃止。

## 参考

- [Flutter Web キャッシュ最適化戦略（Firebase Hosting）](https://gist.github.com/mono0926/266afd3a879d7719ec02ec127adf41e8)
- [Firebase Hosting — Configure Hosting behavior](https://firebase.google.com/docs/hosting/full-config#headers)
- [Firebase Hosting — Manage cache behavior](https://firebase.google.com/docs/hosting/manage-cache)
