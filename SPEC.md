# J-Quants 株価データ取得・週足/月足変換 実装指示書

## 概要

J-Quants API（JPX公式）を使い、日本株の日足OHLCVデータをDartで取得する。
取得した日足データから週足・月足へ集計変換する機能も実装する。

---

## 要件

- 言語：**Dart**（Flutter アプリへの組み込みを想定）
- 対象API：**J-Quants API v1**（ https://jpx-jquants.com/ ）
- 取得データ：日足OHLCV（始値・高値・安値・終値・出来高）
- 変換機能：日足 → 週足・月足への集計
- 認証：メールアドレス＋パスワードによるトークン取得（リフレッシュトークン → IDトークン）

---

## ディレクトリ構成（作成対象）

```
lib/
└── jquants/
    ├── jquants_auth.dart       # 認証・トークン管理
    ├── jquants_client.dart     # APIクライアント（日足取得）
    ├── ohlcv_model.dart        # OHLCVデータモデル
    ├── ohlcv_resampler.dart    # 週足・月足変換ロジック
    └── jquants_service.dart    # 上記をまとめたサービス層
test/
└── jquants/
    └── ohlcv_resampler_test.dart  # 変換ロジックのユニットテスト
```

---

## 実装詳細

### 1. OHLCVモデル（ohlcv_model.dart）

```dart
class OhlcvData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}
```

### 2. 認証フロー（jquants_auth.dart）

J-Quantsの認証は2段階：

**Step 1: リフレッシュトークン取得**
```
POST https://api.jquants.com/v1/token/auth_user
Body: { "mailaddress": "xxx@example.com", "password": "yourpassword" }
Response: { "refreshToken": "..." }
```

**Step 2: IDトークン取得**
```
POST https://api.jquants.com/v1/token/auth_refresh?refreshtoken={refreshToken}
Response: { "idToken": "..." }
```

- IDトークンは有効期限（24時間）を考慮してキャッシュする
- 期限切れの場合は自動的に再取得する
- 認証情報（メール・パスワード）は環境変数または `flutter_secure_storage` で管理する

### 3. 日足データ取得（jquants_client.dart）

```
GET https://api.jquants.com/v1/prices/daily_quotes
Headers: Authorization: Bearer {idToken}
Params:
  - code: 銘柄コード（例: "7203"）
  - from: 開始日（例: "2023-01-01"）
  - to:   終了日（例: "2024-12-31"）
```

レスポンス例：
```json
{
  "daily_quotes": [
    {
      "Date": "2023-01-04",
      "Code": "72030",
      "Open": 1850.0,
      "High": 1900.0,
      "Low": 1840.0,
      "Close": 1880.0,
      "Volume": 12345678.0
    }
  ]
}
```

- `daily_quotes` 配列をパースして `List<OhlcvData>` で返す
- HTTPクライアントは `http` パッケージを使用する

### 4. 週足・月足変換ロジック（ohlcv_resampler.dart）

集計ルール：

| フィールド | 集計方法 |
|-----------|---------|
| date      | 期間の最初の日付（または最後、設定可能に） |
| open      | 期間の**最初**の始値 |
| high      | 期間の**最大**高値 |
| low       | 期間の**最小**安値 |
| close     | 期間の**最後**の終値 |
| volume    | 期間の**合計** |

実装方針：
- 日足リストを受け取り、`groupBy` で週単位・月単位にグループ化する
- 週の区切り：月曜始まり（ISO週）
- 月の区切り：月初〜月末
- `package:collection` の `groupBy` 関数を活用する

```dart
enum ResamplePeriod { weekly, monthly }

class OhlcvResampler {
  static List<OhlcvData> resample(List<OhlcvData> daily, ResamplePeriod period);
  static String _weekKey(DateTime date);   // 例: "2024-W03"
  static String _monthKey(DateTime date);  // 例: "2024-01"
}
```

### 5. サービス層（jquants_service.dart）

上記をまとめたシンプルなAPIを提供する：

```dart
class JQuantsService {
  Future<List<OhlcvData>> fetchDaily(String code, DateTime from, DateTime to);
  Future<List<OhlcvData>> fetchWeekly(String code, DateTime from, DateTime to);
  Future<List<OhlcvData>> fetchMonthly(String code, DateTime from, DateTime to);
}
```

---

## pubspec.yaml への追加パッケージ

```yaml
dependencies:
  http: ^1.2.0
  collection: ^1.18.0

dev_dependencies:
  test: ^1.25.0
```

---

## ユニットテスト（ohlcv_resampler_test.dart）

以下のケースをテストすること：

1. 日足5日分（月〜金）→ 週足1本に正しく集計されること
   - open: 月曜の始値
   - high: 週中の最大高値
   - low: 週中の最小安値
   - close: 金曜の終値
   - volume: 5日分の合計

2. 日足1ヶ月分 → 月足1本に集計されること

3. 空リストを渡した場合、空リストが返ること

4. 週またぎのデータが正しく2本に分割されること

---

## エラーハンドリング

- HTTPステータスが200以外の場合は `JQuantsApiException` をスローする
- 認証失敗（401）は自動リトライ（1回のみ、トークン再取得後）する
- ネットワークエラーは `Exception` をラップしてスローする

---

## 注意事項

- J-Quants無料プランの場合、取得できる過去データは**約2年分（前営業日まで）**
- APIレートリミットに注意し、連続リクエストは適切な間隔を空けること
- 銘柄コードは5桁形式（例: `"72030"`）でレスポンスに含まれるが、クエリパラメータは4桁（`"7203"`）でOK

---

## 実装順序

1. `ohlcv_model.dart` のモデル定義
2. `ohlcv_resampler.dart` の変換ロジック＋テスト
3. `jquants_auth.dart` の認証実装
4. `jquants_client.dart` の APIクライアント実装
5. `jquants_service.dart` のサービス層でまとめる
6. 動作確認（銘柄コード `5255`で直近1年を取得）
