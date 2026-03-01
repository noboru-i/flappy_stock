import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flappy_stock.dart';
import '../services/auth_service.dart';
import 'score_card.dart';
import 'overlay_screen.dart';
import 'stage_select_screen.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  // build の外で生成（毎フレーム再生成を防ぐ）
  late final FlappyStock _game = FlappyStock();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xff1a1a2e),
        body: SafeArea(
          child: Column(
            children: [
              ScoreCard(score: _game.score),
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: SizedBox(
                      width: 400,
                      height: 700,
                      child: GameWidget(
                        game: _game,
                        overlayBuilderMap: {
                          PlayState.welcome.name: (_, _) =>
                              const OverlayScreen(
                                title: 'FLAPPY STOCK',
                                subtitle: 'TAP TO START',
                              ),
                          PlayState.stageSelect.name: (_, game) =>
                              StageSelectScreen(game: game as FlappyStock),
                          PlayState.gameOver.name: (_, _) =>
                              const OverlayScreen(
                                title: 'GAME OVER',
                                subtitle: 'TAP TO RETRY',
                              ),
                          PlayState.clear.name: (_, game) {
                            final flappyStock = game as FlappyStock;
                            return OverlayScreen(
                              title: 'STAGE CLEAR!',
                              subtitle: 'TAP TO RETRY',
                              score: flappyStock.score.value,
                            );
                          },
                        },
                      ),
                    ),
                  ),
                ),
              ),
              _AuthBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          return _SignedInBar(user: user);
        }
        return _SignInButton();
      },
    );
  }
}

class _SignedInBar extends StatelessWidget {
  const _SignedInBar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final nameStyle = GoogleFonts.pressStart2p(
      fontSize: 10,
      color: Colors.white70,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (user.photoURL != null)
                ClipOval(
                  child: Image.network(
                    user.photoURL!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.account_circle, size: 24, color: Colors.white70),
              const SizedBox(width: 8),
              Text(user.displayName ?? user.email ?? '', style: nameStyle),
            ],
          ),
          TextButton(
            onPressed: () => AuthService.instance.signOut(),
            child: Text(
              'SIGN OUT',
              style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton.icon(
        onPressed: () => AuthService.instance.signInWithGoogle(),
        icon: const Icon(Icons.login, size: 16, color: Colors.white70),
        label: Text(
          'SIGN IN WITH GOOGLE',
          style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.white70),
        ),
      ),
    );
  }
}
