// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/screens/wrapper.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'theme.dart';
import 'package:provider/provider.dart';
import 'data/providers/zone_provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/report_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool showOnboarding = true;

  if (prefs.containsKey('showOnboarding')) {
    final bool? onboardingValue = prefs.getBool('showOnboarding');
    showOnboarding = onboardingValue ?? true;
  }

  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  MyApp({Key? key, required this.showOnboarding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'Seguridad Vial App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: showOnboarding ? OnboardingScreen() : Wrapper(),
      ),
    );
  }
}
