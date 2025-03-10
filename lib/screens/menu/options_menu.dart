import 'package:flutter/material.dart';

class OptionsMenu extends StatefulWidget {
  final VoidCallback onBack;

  const OptionsMenu({super.key, required this.onBack});

  @override
  State<OptionsMenu> createState() => _OptionsMenuState();
}

class _OptionsMenuState extends State<OptionsMenu> {
  int _selectedTab = 0;

  final List<String> _tabs = ['Display', 'Sound', 'Controls', 'Other'];
  final List<String> _placeholderContent = [
    'Display settings will go here',
    'Sound settings will go here',
    'Control settings will go here',
    'Other settings will go here',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DefaultTabController(
                length: _tabs.length,
                child: Column(
                  children: [
                    TabBar(
                      onTap: (index) {
                        setState(() {
                          _selectedTab = index;
                        });
                      },
                      tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                      labelColor: Colors.blue.shade900,
                      unselectedLabelColor: Colors.blue.shade300,
                      indicatorColor: Colors.blue.shade900,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _placeholderContent[_selectedTab],
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: widget.onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                ),
                child: const Text('Main menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}