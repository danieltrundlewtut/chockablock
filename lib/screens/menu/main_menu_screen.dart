import 'package:flutter/material.dart';
import 'options_menu.dart';
import 'help_menu.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Widget? _slidingContent;
  bool _isMenuVisible = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-1.0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Close"),
          content: const Text("Are you sure you want to close the app?"),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _slideToNewContent(Widget content, bool slideLeft) {
    setState(() {
      _slidingContent = content;
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0),
        end: Offset(slideLeft ? -1.0 : 1.0, 0),
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOut,
      ));
      _isMenuVisible = false;
    });
    _slideController.forward();
  }

  void _returnToMainMenu() {
    _slideController.reverse().then((_) {
      setState(() {
        _isMenuVisible = true;
        _slidingContent = null;
      });
    });
  }

  List<Widget> _buildMenuButtons(double buttonHeight, BuildContext context) {
    final List<String> buttonTitles = ['Quick game', 'Setup game', 'Options', 'Help', 'Close'];
    final List<VoidCallback> actions = [
          () {}, // Quick game action
          () {}, // Setup game action
          () => _slideToNewContent(
        OptionsMenu(onBack: _returnToMainMenu),
        true,
      ),
          () => _slideToNewContent(
        HelpMenu(onBack: _returnToMainMenu),
        false,
      ),
          () => _showExitConfirmationDialog(context),
    ];

    return List.generate(buttonTitles.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: IntrinsicWidth(
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: actions[index],
              child: Text(buttonTitles[index], style: const TextStyle(fontSize: 20)),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonHeight = screenHeight * 0.08;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
            ),
          ),
          // Main content
          if (_isMenuVisible)
            SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Chock-A-Block',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.04),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _buildMenuButtons(buttonHeight, context),
                      ),
                    ),
                  ),
                  const Spacer()
                ],
              ),
            ),
          // Sliding content (Options and Help menus)
          if (!_isMenuVisible && _slidingContent != null)
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(_slideAnimation.value.dx < 0 ? 1.0 : -1.0, 0),
                end: const Offset(0, 0),
              ).animate(_slideController),
              child: _slidingContent!,
            ),
        ],
      ),
    );
  }
}