import 'package:flutter/material.dart';

import '../../../widgets/profile_settings_view.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ProfileSettingsView(),
      ),
    );
  }
}
