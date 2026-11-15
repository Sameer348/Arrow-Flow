import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_info.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'services/app_services.dart';

class ArrowFlowApp extends StatefulWidget {
  const ArrowFlowApp({super.key});

  @override
  State<ArrowFlowApp> createState() => _ArrowFlowAppState();
}

class _ArrowFlowAppState extends State<ArrowFlowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = context.read<AppServices>().audio;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      audio.onBackground();
    } else if (state == AppLifecycleState.resumed) {
      audio.onForeground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.shortName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        // Keep text readable but stop huge system fonts from breaking layout.
        final mq = MediaQuery.of(context);
        final scaler = mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);
        return MediaQuery(data: mq.copyWith(textScaler: scaler), child: child!);
      },
      home: const HomeScreen(),
    );
  }
}
