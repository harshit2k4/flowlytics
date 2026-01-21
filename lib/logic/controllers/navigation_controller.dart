import 'package:get/get.dart';

// To control bottom navigation bar globally
class NavigationController extends GetxController {
  // 0 = Home, 1 = Analytics, 2 = Me
  var selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}
