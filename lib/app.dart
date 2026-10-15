import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

class ShibirSyllabusApp extends StatelessWidget {
  const ShibirSyllabusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.dark(),
      home: const MainShell(),
    );
  }
}
