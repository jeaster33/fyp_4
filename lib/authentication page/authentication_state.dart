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
        // Show login screen while checking auth state (instead of splash)
        // This prevents users from getting stuck at splash after sign out
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoginScreen();
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your profile...'),
                    ],
                  ),
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
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error loading user data'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Text('Sign Out & Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Check if user document exists
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Special handling for admin
              if (snapshot.data!.email == 'admin@gmail.com') {
                return AdminScreen();
              }
              
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.orange),
                      SizedBox(height: 16),
                      Text('User profile not found'),
                      SizedBox(height: 16),
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
              
              switch (role.toLowerCase()) {
                case 'admin':
                  return AdminScreen();
                case 'student':
                  return StudentHomeScreen();
                case 'teacher':
                  return TeacherHomeScreen();
                default:
                  return HomeScreen();
              }
            } catch (e) {
              print('Error getting role: $e');
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 64, color: Colors.orange),
                      SizedBox(height: 16),
                      Text('User role not defined'),
                      SizedBox(height: 16),
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