# jquants_client

J-Quants API v2 から株価（OHLCV）データを取得し、日足・週足・月足へのリサンプリングを行う Dart パッケージです。

## 機能

- J-Quants API v2 から日次株価データを取得
- 日足データを週足・月足へリサンプリング
- OHLCV データの JSON 入出力

## 前提条件

- Dart SDK `^3.11.0`
- J-Quants API キー（[J-Quants](https://jpx-jquants.com/) で取得）

## 使い方

### CLI スクリプトとして実行

環境変数 `JQUANTS_API_KEY` をセットして実行します:

```sh
JQUANTS_API_KEY=your_api_key dart run bin/jquants_client.dart [証券コード]
```

デフォルトの証券コードは `5255` です。取得データは `output/<証券コード>/` ディレクトリに JSON ファイルとして保存されます:

```
output/5255/
├── daily.json
├── weekly.json
└── monthly.json
```

## API リファレンス

### `JQuantsService`

メインのサービスクラス。API キーを渡して初期化します。

| メソッド | 説明 |
|---|---|
| `fetchDaily(code, from, to)` | 日足データを取得 |
| `fetchWeekly(code, from, to)` | 週足データを取得（日足からリサンプル） |
| `fetchMonthly(code, from, to)` | 月足データを取得（日足からリサンプル） |

### `OhlcvData`

OHLCV データモデル。

| フィールド | 型 | 説明 |
|---|---|---|
| `date` | `DateTime` | 日付 |
| `open` | `double` | 始値 |
| `high` | `double` | 高値 |
| `low` | `double` | 安値 |
| `close` | `double` | 終値 |
| `volume` | `double` | 出来高 |

### `OhlcvResampler`

日足データを週足・月足へリサンプリングするユーティリティ。

```dart
final weekly = OhlcvResampler.resample(dailyData, ResamplePeriod.weekly);
final monthly = OhlcvResampler.resample(dailyData, ResamplePeriod.monthly);
```

### `JQuantsApiException`

API エラー時にスローされる例外。

```dart
try {
  final data = await service.fetchDaily(code, from, to);
} on JQuantsApiException catch (e) {
  print('API Error ${e.statusCode}: ${e.message}');
}
```

## テスト

```sh
dart test
```
