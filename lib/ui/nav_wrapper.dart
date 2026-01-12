import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../logic/controllers/period_controller.dart';

class NavWrapper extends StatefulWidget {
  const NavWrapper({super.key});

  @override
  State<NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<NavWrapper> {
  int _selectedIndex = 0;

  // init controller
  final controller = Get.put(PeriodController());

  // TODO: Replace these placeholders with real screens
  final List<Widget> _pages = [
    const Center(child: Text("Home Screen")),
    const Center(child: Text("Charts & Data")),
    const Center(child: Text("Profile & Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Charts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
