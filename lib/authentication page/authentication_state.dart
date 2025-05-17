import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin_screen.dart';
import '../student page/student_home_screen.dart';
import '../teacher page/teacher_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If not authenticated, show login screen
        if (!snapshot.hasData) {
          return LoginScreen();
        }
        
        // User is authenticated, check role in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            // Show loading while fetching user data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Handle errors fetching user data
            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error loading user data'),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Check if user document exists
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Special handling for admin (optional - you might want to store admin in Firestore too)
              if (snapshot.data!.email == 'admin@gmail.com') {
                return AdminScreen();
              }
              
              // User exists in Auth but not in Firestore - unusual situation
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('User profile not found'),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // User document exists, check role and navigate accordingly
            try {
              String role = userSnapshot.data!.get('role') as String;
              
              switch (role) {
                case 'admin':
                  return AdminScreen();
                case 'student':
                  return StudentHomeScreen();
                case 'teacher':
                  return TeacherHomeScreen();
                default:
                  return HomeScreen(); // Default screen for unknown roles
              }
            } catch (e) {
              // Handle missing or invalid role field
              print('Error getting role: $e');
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('User role not defined'),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}