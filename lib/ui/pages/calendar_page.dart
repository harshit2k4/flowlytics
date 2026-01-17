import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/controllers/period_controller.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CYCLE OVERVIEW",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(child: Text("Calendar View")),
    );
  }
}
