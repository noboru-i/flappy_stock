import 'package:web/web.dart' as web;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flappy_stock.dart';
import '../services/auth_service.dart';
import '../services/ranking_service.dart';
import '../services/tutorial_service.dart';
import 'overlay_screen.dart';
import 'playing_overlay.dart';
import 'ranking_list.dart';
import 'ranking_screen.dart';
import 'stage_select_screen.dart';
import 'tutorial_screen.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  late final FlappyStock _game = FlappyStock();
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final shown = await TutorialService.instance.isTutorialShown();
    if (!shown && mounted) {
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _completeTutorial() async {
    await TutorialService.instance.markTutorialShown();
    if (mounted) {
      setState(() => _showTutorial = false);
    }
  }

  Future<void> _showTutorialAgain() async {
    if (mounted) {
      setState(() => _showTutorial = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xff1a1a2e),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        child: SizedBox(
                          width: 400,
                          height: 700,
                          child: GameWidget(
                            game: _game,
                            overlayBuilderMap: {
                              PlayState.welcome.name: (_, game) =>
                                  _WelcomeOverlay(game: game as FlappyStock),
                              PlayState.stageSelect.name: (_, game) =>
                                  StageSelectScreen(game: game as FlappyStock),
                              PlayState.playing.name: (_, game) =>
                                  PlayingOverlay(game: game as FlappyStock),
                              PlayState.gameOver.name: (_, game) =>
                                  OverlayScreen(
                                    title: 'GAME OVER',
                                    subtitle: 'TAP TO RETRY',
                                    onTap: () =>
                                        (game as FlappyStock).playState =
                                            PlayState.stageSelect,
                                  ),
                              PlayState.clear.name: (_, game) {
                                final flappyStock = game as FlappyStock;
                                return _ClearOverlay(game: flappyStock);
                              },
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  _BottomBar(onShowTutorial: _showTutorialAgain),
                ],
              ),
            ),
            if (_showTutorial) TutorialScreen(onComplete: _completeTutorial),
          ],
        ),
      ),
    );
  }
}

class _WelcomeOverlay extends StatefulWidget {
  const _WelcomeOverlay({required this.game});
  final FlappyStock game;

  @override
  State<_WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<_WelcomeOverlay> {
  bool _showRanking = false;

  @override
  Widget build(BuildContext context) {
    if (_showRanking) {
      return RankingScreen(
        game: widget.game,
        onClose: () => setState(() => _showRanking = false),
      );
    }

    final titleStyle = GoogleFonts.pressStart2p(
      fontSize: 28,
      color: const Color(0xff184e77),
    );
    final buttonStyle = GoogleFonts.pressStart2p(
      fontSize: 14,
      color: Colors.white,
    );

    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data != null;
        return Container(
          alignment: const Alignment(0, -0.15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FLAPPY\nSTOCK',
                style: titleStyle,
                textAlign: TextAlign.center,
              ).animate().slideY(duration: 750.ms, begin: -3, end: 0),
              const SizedBox(height: 40),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () =>
                      widget.game.playState = PlayState.stageSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff184e77),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text('START', style: buttonStyle),
                ),
              ),
              if (isLoggedIn) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showRanking = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff184e77),
                      side: const BorderSide(
                        color: Color(0xff184e77),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'RANKING',
                      style: buttonStyle.copyWith(
                        color: const Color(0xff184e77),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ClearOverlay extends StatefulWidget {
  const _ClearOverlay({required this.game});
  final FlappyStock game;

  @override
  State<_ClearOverlay> createState() => _ClearOverlayState();
}

class _ClearOverlayState extends State<_ClearOverlay> {
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _submitScore();
  }

  Future<void> _submitScore() async {
    if (_submitted) return;
    final stageId = widget.game.currentStageId;
    if (stageId == null) return;
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    _submitted = true;
    await RankingService.instance.submitScore(stageId, widget.game.finalValue);
  }

  @override
  Widget build(BuildContext context) {
    final stageId = widget.game.currentStageId;
    final user = AuthService.instance.currentUser;

    return OverlayScreen(
      title: 'STAGE CLEAR!',
      subtitle: 'TAP TO RETRY',
      finalValue: widget.game.finalValue,
      rankingWidget: (user != null && stageId != null)
          ? RankingList(stageId: stageId)
          : null,
      onTap: () => widget.game.playState = PlayState.stageSelect,
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onShowTutorial});

  final VoidCallback onShowTutorial;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (user != null)
                Row(
                  children: [
                    if (user.photoURL != null)
                      ClipOval(
                        child: Image.network(
                          user.photoURL!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.account_circle,
                            size: 24,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.account_circle,
                        size: 24,
                        color: Colors.white70,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      user.displayName ?? user.email ?? '',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: () => _handleSignIn(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                  ),
                  icon: const Icon(
                    Icons.login,
                    size: 16,
                    color: Colors.white70,
                  ),
                  label: Text(
                    'SIGN IN',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                  ),
                ),
              PopupMenuButton<_MenuAction>(
                icon: const Icon(Icons.menu, color: Colors.white54, size: 20),
                color: const Color(0xff2a2a3e),
                onSelected: (action) {
                  switch (action) {
                    case _MenuAction.signIn:
                      break;
                    case _MenuAction.signOut:
                      AuthService.instance.signOut();
                    case _MenuAction.tutorial:
                      onShowTutorial();
                    case _MenuAction.terms:
                      web.window.open('terms_of_service.html', '_blank');
                    case _MenuAction.privacy:
                      web.window.open('privacy_policy.html', '_blank');
                    case _MenuAction.github:
                      web.window.open(
                        'https://github.com/noboru-i/flappy_stock',
                        '_blank',
                      );
                  }
                },
                itemBuilder: (_) => [
                  if (user != null)
                    PopupMenuItem(
                      value: _MenuAction.signOut,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SIGN OUT',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: _MenuAction.tutorial,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.help_outline,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TUTORIAL',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.terms,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TERMS',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.privacy,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.privacy_tip_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PRIVACY',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.github,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.code,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GitHub',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      await AuthService.instance.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'unauthorized-domain'
          ? 'モンスターラボのアカウント（@monstar-lab.com）でログインしてください。'
          : (e.message ?? 'サインインに失敗しました。');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('サインインに失敗しました。')));
    }
  }
}

enum _MenuAction { signIn, signOut, tutorial, terms, privacy, github }
