import 'dart:js_interop';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:web/web.dart' as web;
import 'firebase_options.dart';
import 'src/widgets/game_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }
  if (kIsWeb) {
    web.document.addEventListener(
      'contextmenu',
      ((web.Event e) => e.preventDefault()).toJS,
    );
  }
  runApp(const GameApp());
}
