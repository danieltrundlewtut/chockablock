import 'package:flutter/material.dart';

import '../screens/menu/main_menu_screen.dart';

class CoordinatedSlideTransition extends PageRouteBuilder {
  final Widget enterPage;
  final bool slideFromLeft;

  CoordinatedSlideTransition({
    required this.enterPage,
    required this.slideFromLeft,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => enterPage,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      // Animation for the entering page
      var slideIn = Tween<Offset>(
        begin: Offset(slideFromLeft ? -1.0 : 1.0, 0.0),
        end: Offset.zero,
      ).animate(curve);

      // Animation for the exiting page (main menu)
      var slideOut = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(slideFromLeft ? 1.0 : -1.0, 0.0),
      ).animate(curve);

      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Persistent background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade700, Colors.blue.shade900],
                  ),
                ),
              ),
              // Main menu sliding out
              FractionalTranslation(
                translation: Offset(slideOut.value.dx, 0),
                child: const MainMenuScreen(),
              ),
              // New page sliding in
              FractionalTranslation(
                translation: Offset(slideIn.value.dx, 0),
                child: child,
              ),
            ],
          );
        },
        child: child,
      );
    },
  );
}