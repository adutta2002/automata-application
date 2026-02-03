import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/pos_provider.dart';
import 'providers/tab_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'screens/shell_screen.dart';
import 'screens/login_screen.dart';
import 'providers/settings_provider.dart';

import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => POSProvider()),
        ChangeNotifierProvider(create: (_) => TabProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const AutomataApp(),
    ),
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setTitleBarStyle(TitleBarStyle.normal); // Explicitly ensure normal style
    await windowManager.setFullScreen(false); // Ensure not in fullscreen
    // await windowManager.maximize(); // Commented out to prevent fullscreen
  });
}

class AutomataApp extends StatelessWidget {
  const AutomataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automata POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (authProvider.isAuthenticated) {
            // Load POS data moved to ShellScreen initState to prevent duplicates
            return const ShellScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
