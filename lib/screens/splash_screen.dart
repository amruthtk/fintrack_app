import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    // Bounce from 0 (at the 'ı') to -35 (above the 'ı')
    _bounceAnimation = Tween<double>(begin: 0.0, end: -35.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine, // Smoother bounce physics
      ),
    );

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final provider = context.read<AppProvider>();
    final user = provider.user;
    final isLoggedIn = user != null;

    if (!isLoggedIn) {
      context.go('/auth');
    } else {
      final needsCalibration =
          user.wealthCalibrationComplete != true &&
          !user.wallets.any((w) => w.balance > 0);
      if (needsCalibration) {
        context.go('/calibration');
      } else {
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon & Text Container
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Zap Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF2563EB),
                    size: 44,
                  ),
                ),
                const SizedBox(width: 20),
                // FinTrack Text with precisely positioned dot
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'F',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -4.0,
                      ),
                    ),
                    // The Dotless 'ı' and its Bouncing Dot
                    Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        const Text(
                          'ı',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -4.0,
                          ),
                        ),
                        // Dot is positioned relative to the 'ı' box
                        Positioned(
                          top: 18, // Baseline for dot
                          left:
                              14, // Adjusted for the italic slant to stay on top of the 'ı' stem
                          child: AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _bounceAnimation.value - 10),
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white24,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'nTrack',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -4.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
