import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Game tool/ScoreboardPage.dart';
import '../Training Tool/training_type.dart';
import '../authentication page/splash_screen.dart';
import 'calender_coach_screen.dart';
import 'schedule_date_screen.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'Coach/Teacher';
    final String? photoURL = user?.photoURL;
    final String userId = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                      child: photoURL == null
                          ? Icon(Icons.person, size: 50, color: Colors.grey.shade700)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome, $displayName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  // Gameboard card
                  _buildFeatureCard(
                    context,
                    icon: Icons.sports_handball,
                    title: 'Gameboard',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SepakTakrawApp(),
                        ),
                      );
                    },
                  ),
                  // Training card - Updated to go directly to TrainingTypesPage
                  _buildFeatureCard(
                    context,
                    icon: Icons.fitness_center,
                    title: 'Training',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrainingTypesPage(
                            userId: userId,
                            displayName: displayName,
                          ),
                        ),
                      );
                    },
                  ),
                  // Calendar card
_buildFeatureCard(
  context,
  icon: Icons.add,
  title: 'Make Session',
  color: const Color.fromARGB(255, 176, 110, 39),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleDateScreen(
          userId: userId,
        ),
      ),
    );
  },
),
                  // Placeholder for future features
                  // Schedule List card
                  _buildFeatureCard(
                    context,
                    icon: Icons.calendar_month,
                    title: 'Schedule List',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleListScreen(
                            userId: userId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}