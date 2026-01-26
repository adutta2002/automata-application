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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
            // Load POS data after authentication
            context.read<POSProvider>().loadInitialData();
            return const ShellScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
