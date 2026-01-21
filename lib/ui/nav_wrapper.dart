import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home/home_screen.dart';
import 'charts/charts_screen.dart';
import 'me/me_screen.dart';
import '../logic/controllers/navigation_controller.dart';

class NavWrapper extends StatelessWidget {
  const NavWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Connect to the global controller
    final navController = Get.find<NavigationController>();

    final List<Widget> pages = [
      const HomeScreen(),
      const ChartsScreen(),
      const MeScreen(),
    ];

    return Scaffold(
      // Obx ensures the UI refreshes when the notification changes the index
      body: Obx(() => pages[navController.selectedIndex.value]),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: navController.selectedIndex.value,
          onDestinationSelected: (int index) {
            navController.changeIndex(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
