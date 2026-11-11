// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dentel_connect/firebase_options.dart';
import 'package:dentel_connect/screens/auth/login_screen.dart';
import 'package:dentel_connect/services/auth_provider.dart';
import 'package:dentel_connect/services/order_provider.dart';
import 'package:dentel_connect/utils/constants.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DentalConnectApp());
}

class DentalConnectApp extends StatelessWidget {
  const DentalConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );
  }
}
