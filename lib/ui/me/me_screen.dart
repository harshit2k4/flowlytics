import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/controllers/period_controller.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize controller with the saved name from Hive
    final controller = Get.find<PeriodController>();
    _nameController = TextEditingController(text: controller.userName.value);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            // Update title on the go
            title: Obx(
              () => Text(
                controller.userName.value == "Beautiful Girl"
                    ? "Hello Beautiful Girl"
                    : "Hello ${controller.userName.value}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(context, controller),
                  const SizedBox(height: 40),

                  Obx(() {
                    bool isMLActive = controller.allLogs.length >= 3;
                    return Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfo(
                            context,
                            Icons.shield_outlined,
                            "Private",
                            "Local Data",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCompactInfo(
                            context,
                            Icons.memory_outlined,
                            "Engine",
                            isMLActive ? "Weighted ML" : "Bio Average",
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 48),
                  _buildDangerZone(context, controller),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    PeriodController controller,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.favorite_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text("Heya!", style: TextStyle(fontSize: 16)),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 40),
            _isEditing
                ? Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: TextField(
                      controller: _nameController,
                      focusNode: _focusNode,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      maxLength: 15,
                      // Save on submit
                      onSubmitted: (val) {
                        controller.updateName(val);
                        setState(() => _isEditing = false);
                      },
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: "",
                      ),
                    ),
                  )
                : Flexible(
                    child: Obx(
                      () => Text(
                        controller.userName.value,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
            IconButton(
              onPressed: () {
                if (_isEditing) {
                  // If clicking Checkmark, save logic
                  controller.updateName(_nameController.text);
                }
                setState(() => _isEditing = !_isEditing);
                if (_isEditing) _focusNode.requestFocus();
              },
              icon: Icon(
                _isEditing ? Icons.check_circle : Icons.edit_outlined,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactInfo(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          FittedBox(
            child: Text(sub, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, PeriodController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        ListTile(
          onTap: () => _showDeleteDialog(context, controller),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          tileColor: Colors.red.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
          title: const Text(
            "Wipe All Data",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.red),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, PeriodController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Wipe?"),
        content: const Text(
          "This acts as an emergency reset. All logs and your name's history will be deleted.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              // Invoke wipe function in periods controller
              await controller.wipeData();

              // Reset local text field
              setState(() {
                _nameController.text = "Beautiful Girl";
                _isEditing = false;
              });

              Get.back();
              _showGlassySnackbar(context, "All data and settings wiped");
            },
            child: const Text("Wipe", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showGlassySnackbar(BuildContext context, String message) {
    Get.rawSnackbar(
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.transparent,
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
