import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class SpinWheelScreen extends StatefulWidget {
  final List<String> memberNames;
  final String groupName;

  const SpinWheelScreen({
    super.key,
    required this.memberNames,
    required this.groupName,
  });

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  String? _selectedMember;
  final _random = math.Random();

  // Vibrant colors for wheel segments
  static const List<Color> _segmentColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFF43F5E), // Rose
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFF84CC16), // Lime
    Color(0xFFA855F7), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning || widget.memberNames.length < 2) return;

    setState(() {
      _isSpinning = true;
      _selectedMember = null;
    });

    // Random number of full rotations (5-10) + landing position
    final extraTurns = 5 + _random.nextInt(6);
    final segmentAngle = 2 * math.pi / widget.memberNames.length;
    // Pick a random segment to land on
    final targetSegment = _random.nextInt(widget.memberNames.length);
    // The angle to that segment center, measured from the pointer at top
    final targetAngle = extraTurns * 2 * math.pi +
        (2 * math.pi - targetSegment * segmentAngle - segmentAngle / 2);

    _animation = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const _DecelerateCurve(),
    ));

    _animation.addListener(() {
      setState(() {
        _currentAngle = _animation.value;
      });
    });

    _controller.reset();
    _controller.forward().then((_) {
      setState(() {
        _isSpinning = false;
        _selectedMember = widget.memberNames[targetSegment];
      });
      _showResultDialog();
    });
  }

  void _showResultDialog() {
    if (_selectedMember == null) return;

    final funMessages = [
      'Time to open that wallet!',
      'Your treat today!',
      'Better luck next time!',
      'The wheel has spoken!',
      'Pay up, buttercup!',
      'Cha-ching! It\'s your turn!',
      'Bullseye! You\'re paying!',
      'The odds were NOT in your favor!',
    ];
    final funMessage = funMessages[_random.nextInt(funMessages.length)];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (dialogContext, anim1, anim2) {
        return _ResultPopup(
          animation: anim1,
          selectedMember: _selectedMember!,
          funMessage: funMessage,
          onClose: () => Navigator.pop(dialogContext),
          onSpinAgain: () {
            Navigator.pop(dialogContext);
            _spin();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = widget.memberNames;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        title: Text(
          'Spin the Wheel!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Subtitle
          Text(
            '${widget.groupName} • Who pays?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),

          // Fun banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎰', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Spin to decide who pays the bill!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

          // Wheel area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wheelSize = math.min(
                      constraints.maxWidth - 32,
                      constraints.maxHeight - 80,
                    ).clamp(200.0, 380.0);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pointer triangle
                        CustomPaint(
                          size: const Size(30, 20),
                          painter: _PointerPainter(isDark: isDark),
                        ).animate().fadeIn(delay: 400.ms),
                        // The wheel
                        SizedBox(
                          width: wheelSize,
                          height: wheelSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow ring
                              Container(
                                width: wheelSize + 12,
                                height: wheelSize + 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withValues(alpha: _isSpinning ? 0.5 : 0.2),
                                      blurRadius: _isSpinning ? 30 : 15,
                                      spreadRadius: _isSpinning ? 2 : 0,
                                    ),
                                  ],
                                ),
                              ),
                              // Wheel
                              Transform.rotate(
                                angle: _currentAngle,
                                child: CustomPaint(
                                  size: Size(wheelSize, wheelSize),
                                  painter: _WheelPainter(
                                    members: members,
                                    colors: _segmentColors,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              // Center button
                              GestureDetector(
                                onTap: _spin,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: wheelSize * 0.22,
                                  height: wheelSize * 0.22,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isSpinning
                                          ? [
                                              const Color(0xFFF59E0B),
                                              const Color(0xFFF97316),
                                            ]
                                          : [
                                              const Color(0xFF6366F1),
                                              const Color(0xFF8B5CF6),
                                            ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isSpinning
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFF6366F1))
                                            .withValues(alpha: 0.5),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _isSpinning ? '🔥' : 'SPIN',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: _isSpinning
                                            ? wheelSize * 0.055
                                            : wheelSize * 0.04,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms).scale(
                              begin: const Offset(0.7, 0.7),
                              curve: Curves.easeOutBack,
                              duration: 600.ms,
                            ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // Big spin button at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSpinning ? null : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  disabledBackgroundColor:
                      const Color(0xFF6366F1).withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSpinning) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Spinning...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else ...[
                      const Text('🎰', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(
                        'Spin the Wheel!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

// ── Stunning Result Popup ──
class _ResultPopup extends StatefulWidget {
  final Animation<double> animation;
  final String selectedMember;
  final String funMessage;
  final VoidCallback onClose;
  final VoidCallback onSpinAgain;

  const _ResultPopup({
    required this.animation,
    required this.selectedMember,
    required this.funMessage,
    required this.onClose,
    required this.onSpinAgain,
  });

  @override
  State<_ResultPopup> createState() => _ResultPopupState();
}

class _ResultPopupState extends State<_ResultPopup>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late Animation<double> _pulseAnimation;
  final _random = math.Random();
  late List<_ConfettiParticle> _confetti;

  @override
  void initState() {
    super.initState();

    // Pulsating glow animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Generate confetti particles
    _confetti = List.generate(25, (_) => _ConfettiParticle.random(_random));

    // Confetti float animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _pulseAnimation, _confettiController]),
      builder: (context, child) {
        final scale = Curves.easeOutBack.transform(
          widget.animation.value.clamp(0.0, 1.0),
        );
        final opacity = widget.animation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Stack(
            children: [
              // ── Floating confetti particles ──
              ...List.generate(_confetti.length, (i) {
                final p = _confetti[i];
                final progress = (_confettiController.value + p.delay) % 1.0;
                final y = screenSize.height * (1 - progress);
                final x = p.x * screenSize.width +
                    math.sin(progress * math.pi * 2 + p.phase) * 30;
                final particleOpacity = (1 - (progress - 0.7).clamp(0.0, 0.3) / 0.3) *
                    opacity *
                    0.9;

                return Positioned(
                  left: x,
                  top: y,
                  child: Transform.rotate(
                    angle: progress * math.pi * 3 + p.phase,
                    child: Opacity(
                      opacity: particleOpacity.clamp(0.0, 1.0),
                      child: Text(
                        p.emoji,
                        style: TextStyle(fontSize: p.size),
                      ),
                    ),
                  ),
                );
              }),

              // ── Main dialog ──
              Center(
                child: Transform.scale(
                  scale: scale,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        // Multi-layered glow
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.4 * _pulseAnimation.value),
                            blurRadius: 60,
                            spreadRadius: -10,
                          ),
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2 * _pulseAnimation.value),
                            blurRadius: 40,
                            spreadRadius: -5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1F3A),
                                Color(0xFF0F172A),
                                Color(0xFF15122B),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: Container(
                            // Subtle shimmer overlay
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Color.lerp(
                                  const Color(0xFF6366F1),
                                  const Color(0xFFF59E0B),
                                  _pulseAnimation.value,
                                )!.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── Crown / celebration row ──
                                const Text('👑', style: TextStyle(fontSize: 42))
                                    .animate()
                                    .fadeIn(delay: 200.ms, duration: 400.ms)
                                    .slideY(begin: -0.5)
                                    .then()
                                    .shimmer(
                                      delay: 500.ms,
                                      duration: 1500.ms,
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                    ),

                                const SizedBox(height: 6),

                                // ── Fun message ──
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    widget.funMessage,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 350.ms, duration: 400.ms)
                                    .slideY(begin: 0.3),

                                const SizedBox(height: 20),

                                // ── Glowing avatar ──
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Animated glow ring
                                    Container(
                                      width: 108,
                                      height: 108,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Color.lerp(
                                            const Color(0xFF6366F1),
                                            const Color(0xFFF59E0B),
                                            _pulseAnimation.value,
                                          )!.withValues(alpha: 0.5),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1)
                                                .withValues(alpha: 0.3 * _pulseAnimation.value),
                                            blurRadius: 24,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Dashed ring effect
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        widget.selectedMember.isNotEmpty
                                            ? widget.selectedMember[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                    .animate()
                                    .fadeIn(delay: 450.ms, duration: 500.ms)
                                    .scale(
                                      begin: const Offset(0.3, 0.3),
                                      curve: Curves.easeOutBack,
                                    ),

                                const SizedBox(height: 18),

                                // ── Name with shimmer ──
                                Text(
                                  widget.selectedMember,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                                    .animate()
                                    .fadeIn(delay: 600.ms, duration: 400.ms)
                                    .slideY(begin: 0.3)
                                    .then()
                                    .shimmer(
                                      delay: 300.ms,
                                      duration: 1800.ms,
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                                    ),

                                const SizedBox(height: 4),

                                // ── "has to pay" badge ──
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                        const Color(0xFFF97316).withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('💳', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'HAS TO PAY!',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFF59E0B),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 750.ms, duration: 400.ms)
                                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

                                const SizedBox(height: 28),

                                // ── Action buttons ──
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          child: InkWell(
                                            onTap: widget.onClose,
                                            borderRadius: BorderRadius.circular(16),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              child: Center(
                                                child: Text(
                                                  'Done',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          child: InkWell(
                                            onTap: widget.onSpinAgain,
                                            borderRadius: BorderRadius.circular(16),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text('🔄', style: TextStyle(fontSize: 16)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Spin Again!',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                    .animate()
                                    .fadeIn(delay: 900.ms, duration: 400.ms)
                                    .slideY(begin: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Confetti particle data
class _ConfettiParticle {
  final double x;
  final double delay;
  final double phase;
  final double size;
  final String emoji;

  _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.phase,
    required this.size,
    required this.emoji,
  });

  static _ConfettiParticle random(math.Random r) {
    const emojis = ['🎉', '🎊', '✨', '⭐', '💫', '🌟', '🎈', '💰', '💸', '🤑', '💵', '🪙', '🎯', '🔥', '💎'];
    return _ConfettiParticle(
      x: r.nextDouble(),
      delay: r.nextDouble(),
      phase: r.nextDouble() * math.pi * 2,
      size: 12 + r.nextDouble() * 14,
      emoji: emojis[r.nextInt(emojis.length)],
    );
  }
}

class _DecelerateCurve extends Curve {
  const _DecelerateCurve();

  @override
  double transformInternal(double t) {
    // Cubic ease-out for smooth deceleration
    return 1 - math.pow(1 - t, 3).toDouble();
  }
}

// Pointer triangle pointing down at the wheel
class _PointerPainter extends CustomPainter {
  final bool isDark;
  _PointerPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    // Shadow
    canvas.drawShadow(path, const Color(0xFF6366F1), 6, true);
    canvas.drawPath(path, paint);

    // White outline
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// The actual wheel with segments
class _WheelPainter extends CustomPainter {
  final List<String> members;
  final List<Color> colors;
  final bool isDark;

  _WheelPainter({
    required this.members,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / members.length;

    // Draw segments
    for (int i = 0; i < members.length; i++) {
      final startAngle = -math.pi / 2 + i * segmentAngle;
      final color = colors[i % colors.length];

      // Segment fill
      final segmentPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, segmentPaint);

      // Lighter inner gradient overlay
      final overlayPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawPath(path, overlayPaint);

      // Segment border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);

      // Draw member name
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.62;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + math.pi / 2);

      // Truncate name if needed
      String displayName = members[i];
      if (displayName.length > 10) {
        displayName = '${displayName.substring(0, 9)}…';
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.black38,
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();

      // Draw emoji at outer edge
      final emojiRadius = radius * 0.85;
      final emojiX = center.dx + emojiRadius * math.cos(textAngle);
      final emojiY = center.dy + emojiRadius * math.sin(textAngle);

      canvas.save();
      canvas.translate(emojiX, emojiY);

      final emojiPainter = TextPainter(
        text: TextSpan(
          text: _getMemberEmoji(i),
          style: const TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      emojiPainter.paint(
        canvas,
        Offset(-emojiPainter.width / 2, -emojiPainter.height / 2),
      );
      canvas.restore();
    }

    // Outer ring
    final outerRingPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, outerRingPaint);

    // Decorative dots on the outer ring
    final dotCount = members.length * 3;
    for (int i = 0; i < dotCount; i++) {
      final angle = 2 * math.pi * i / dotCount;
      final dotX = center.dx + (radius + 0.5) * math.cos(angle);
      final dotY = center.dy + (radius + 0.5) * math.sin(angle);
      final dotPaint = Paint()
        ..color = i % 3 == 0
            ? const Color(0xFFF59E0B)
            : Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), 2.5, dotPaint);
    }
  }

  String _getMemberEmoji(int index) {
    const emojis = ['😎', '🤪', '😂', '🥳', '🤑', '😱', '🤡', '👻', '🦄', '🐸', '🎃', '💀'];
    return emojis[index % emojis.length];
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.members != members;
  }
}
