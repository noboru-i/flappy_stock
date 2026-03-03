import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _TutorialPage(
      title: 'FLAPPY STOCK とは？',
      body: '株価ローソク足を通過しながら飛ぶゲーム！\n\n実際の株価データがステージになる！',
      icon: Icons.candlestick_chart,
    ),
    _TutorialPage(
      title: '取引モード',
      body: 'ローソク足を通過するたびに取引が実行される！\n\n・買い：現金を全額使って購入\n・売り：保有株を全株売却\n・空売り：100株を借りて売る（次の通過時に自動決済）',
      icon: Icons.swap_horiz,
    ),
    _TutorialPage(
      title: '操作方法',
      body: 'モードのボタンを長押し → 上昇\n長押しほど力強く飛べる！\n\n離す → 下降',
      icon: Icons.touch_app,
    ),
    _TutorialPage(
      title: '売買価格のしくみ',
      body: '通過した高さが売買価格になる！\n低い位置で買い、高い位置で売ろう\n\n空売り：先に高く売り後で安く買い戻す',
      icon: Icons.price_change,
    ),
    _TutorialPage(
      title: '目標',
      body: '評価額を最大化してランキング1位へ！',
      icon: Icons.emoji_events,
    ),
  ];

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _goPrev() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == _pages.length - 1;

    return Container(
      color: const Color(0xff1a1a2e),
      child: SafeArea(
        child: Column(
          children: [
            // SKIP ボタン（最終ページでは非表示）
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: Visibility(
                  visible: !isLastPage,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      'SKIP',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 13,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ページコンテンツ
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            // ページインジケーター
            _PageIndicator(count: _pages.length, current: _currentPage),
            const SizedBox(height: 20),
            // PREV / NEXT(START) ボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // PREV（最初のページでは透明・無効化）
                  Opacity(
                    opacity: isFirstPage ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: isFirstPage,
                      child: OutlinedButton(
                        onPressed: _goPrev,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          'PREV',
                          style: GoogleFonts.pressStart2p(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  // NEXT / START
                  ElevatedButton(
                    onPressed: _goNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26A69A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      isLastPage ? 'START' : 'NEXT',
                      style: GoogleFonts.pressStart2p(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: const Color(0xFF26A69A)),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 20 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: active ? const Color(0xFF26A69A) : Colors.white24,
          ),
        );
      }),
    );
  }
}
