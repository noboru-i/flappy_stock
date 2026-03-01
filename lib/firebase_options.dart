// このファイルは `flutterfire configure` コマンドで自動生成されます。
// 以下の手順でセットアップしてください:
//
//   1. FlutterFire CLI をインストール:
//      dart pub global activate flutterfire_cli
//
//   2. プロジェクトルートで実行:
//      flutterfire configure --project=flappy-stock-prod
//
//   3. 生成された firebase_options.dart でこのファイルを置き換えてください。
//
// 参考: https://firebase.flutter.dev/docs/overview/#using-the-flutterfire-cli

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: `flutterfire configure` を実行して以下の値を置き換えてください。
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'flappy-stock-prod',
    authDomain: 'flappy-stock-prod.firebaseapp.com',
    storageBucket: 'flappy-stock-prod.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'flappy-stock-prod',
    storageBucket: 'flappy-stock-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'flappy-stock-prod',
    storageBucket: 'flappy-stock-prod.firebasestorage.app',
    iosClientId: 'TODO',
    iosBundleId: 'TODO',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'flappy-stock-prod',
    storageBucket: 'flappy-stock-prod.firebasestorage.app',
    iosClientId: 'TODO',
    iosBundleId: 'TODO',
  );
}
