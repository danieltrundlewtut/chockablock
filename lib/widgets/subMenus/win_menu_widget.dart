import 'package:flutter/material.dart';
import '../../screens/menu/main_menu_screen.dart';

class WinMenu extends StatefulWidget {
  final VoidCallback onNewGame;
  final VoidCallback onDismiss;
  final int score;
  final int moveCount;
  final int secondsTaken;

  const WinMenu({
    super.key,
    required this.onNewGame,
    required this.onDismiss,
    this.score = 0,
    this.moveCount = 0,
    this.secondsTaken = 0,
  });

  @override
  State<WinMenu> createState() => _WinMenuState();
}

class _WinMenuState extends State<WinMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You Win!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Score: ${widget.score}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(widget.secondsTaken),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.swap_vert, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.moveCount} moves',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildMenuButton(
                'Admire Solution',
                widget.onDismiss,
                backgroundColor: Colors.blue,
              ),
              _buildMenuButton(
                'Start New Game',
                widget.onNewGame,
                backgroundColor: Colors.blue,
              ),
              _buildMenuButton(
                'Return to Menu',
                    () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MainMenuScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      String text,
      VoidCallback onPressed, {
        Color backgroundColor = Colors.blue,
        IconData? icon,
      }) {
    final wrappedOnPressed = text == 'Admire Solution' ? () {
      onPressed();
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          setState(() {});
        }
      });
    } : onPressed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: wrappedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}