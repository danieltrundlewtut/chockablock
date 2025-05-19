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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;

    final menuWidth = screenSize.width < 400 ? screenSize.width * 0.85 : 300.0;

    final titleFontSize = screenSize.height < 700 ? 22.0 : 30.0;
    final scoreFontSize = screenSize.height < 700 ? 18.0 : 22.0;
    final statsFontSize = screenSize.height < 700 ? 10.0 : 12.0;
    final buttonFontSize = screenSize.height < 700 ? 14.0 : 16.0;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: menuWidth,
          padding: EdgeInsets.all(isSmallScreen ? 10 : 18),
          constraints: BoxConstraints(maxHeight: screenSize.height * 0.8),
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
              Text(
                'You Win!',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 12),

              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
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
                          style: TextStyle(
                            fontSize: scoreFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(widget.secondsTaken),
                                style: TextStyle(
                                  fontSize: statsFontSize,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Icon(Icons.swap_vert, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.moveCount} moves',
                                style: TextStyle(
                                  fontSize: statsFontSize,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 6 : 14),
              _buildMenuButton(
                'Admire Solution',
                widget.onDismiss,
                backgroundColor: Colors.blue,
                buttonFontSize: buttonFontSize,
              ),
              _buildMenuButton(
                'Start New Game',
                widget.onNewGame,
                backgroundColor: Colors.blue,
                buttonFontSize: buttonFontSize,
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
                buttonFontSize: buttonFontSize,
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
        required double buttonFontSize,
      }) {
    final isSmallScreen = MediaQuery.of(context).size.height < 600;

    final wrappedOnPressed = text == 'Admire Solution' ? () {
      onPressed();
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          setState(() {});
        }
      });
    } : onPressed;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 3 : 5),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: wrappedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: isSmallScreen ? 14 : 18),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: TextStyle(fontSize: buttonFontSize),
              ),
            ],
          ),
        ),
      ),
    );
  }
}