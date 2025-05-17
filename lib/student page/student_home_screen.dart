import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../authentication page/splash_screen.dart';

// Import these pages
import 'profile_page.dart';
import 'performance_page.dart';
import 'student_schedule_list_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _fullName = 'Student';
  String _username = '';
  String _profileImageUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();
        
        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
          setState(() {
            _fullName = data['fullName'] ?? 'Student';
            _username = data['username'] ?? '';
            _profileImageUrl = data['profileImageUrl'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Home'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                onProfileUpdated: _loadUserData,
              ),
            ),
          );
        },
        child: Hero(
          tag: 'profilePicture',
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _profileImageUrl.isNotEmpty 
                ? NetworkImage(_profileImageUrl) 
                : null,
            child: _profileImageUrl.isEmpty
                ? Icon(Icons.person, size: 50, color: Colors.grey.shade700)
                : null,
          ),
        ),
      ),
      SizedBox(height: 12),
      Text(
        'Welcome, $_username!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        _fullName,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
      ),
      SizedBox(height: 4),
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
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              onProfileUpdated: _loadUserData,
                            ),
                          ),
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
                      title: 'Training Schedule',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentScheduleListScreen(
                              userId: _auth.currentUser?.uid ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // QR Attendance card
                    _buildFeatureCard(
                      context,
                      icon: Icons.qr_code_scanner,
                      title: 'Attendance',
                      color: Colors.purple,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('QR Attendance feature coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Training recommendations section
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fitness_center, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Training Recommendations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Knee Position Improvement'),
                          subtitle: Text('Focus on maintaining proper knee position during serves'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate to detailed recommendation
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Defensive Positioning'),
                          subtitle: Text('Practice defensive positioning drills'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate to detailed recommendation
                          },
                        ),
                      ],
                    ),
                  ),
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