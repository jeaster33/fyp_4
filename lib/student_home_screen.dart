import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'splash_screen.dart';

// Import these new pages (you'll need to create them)
import 'student page/profile_page.dart';
import 'student page/performance_page.dart';
import 'student page/calendar_page.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'Student';
    final String? photoURL = user?.photoURL;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
              // Profile section with picture
              Center(
                child: Column(
                  children: [
                    // Profile picture
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilePage()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                        child: photoURL == null
                            ? Icon(Icons.person, size: 50, color: Colors.grey.shade700)
                            : null,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome, $displayName!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap on your profile picture to edit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Menu section
              Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              
              // Feature menu cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  // Profile card
                  _buildFeatureCard(
                    context,
                    icon: Icons.person,
                    title: 'My Profile',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                  ),
                  
                  // Performance card
                  _buildFeatureCard(
                    context,
                    icon: Icons.insights,
                    title: 'Performance',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PerformancePage()),
                      );
                    },
                  ),
                  
                  // Calendar card
                  _buildFeatureCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Event Calendar',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CalendarPage()),
                      );
                    },
                  ),
                  
                  // Assignments card (bonus feature)
                  _buildFeatureCard(
                    context,
                    icon: Icons.assignment,
                    title: 'Assignments',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Create and navigate to assignments page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Assignments feature coming soon!')),
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
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
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