import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'authentication page/authentication_state.dart';
import 'service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sepak Takraw Training',
      debugShowCheckedModeBanner: false, // Add this line to remove debug banner
      home: AuthWrapper(), // Changed from SplashScreen() to AuthWrapper()
    );
  }
}