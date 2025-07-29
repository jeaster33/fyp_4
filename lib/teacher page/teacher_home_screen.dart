import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Game tool/ScoreboardPage.dart';
import '../Training Tool/training_page.dart';
import '../authentication page/splash_screen.dart';
import '../Generate_report.dart';
import 'calender_coach_screen.dart';
import 'schedule_date_screen.dart';
import 'teacher_profile_page.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  _TeacherHomeScreenState createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = 'Coach';
  String _fullName = '';
  String _profileImageUrl = '';
  bool _isLoading = true;

  // Dynamic statistics variables
  int _upcomingSessions = 0;
  int _totalStudents = 0;
  String _currentWeek = 'N/A';
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
          setState(() {
            _username = data['username'] ?? 'Coach';
            _fullName = data['fullName'] ?? '';
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

  Future<void> _loadStatistics() async {
    setState(() {
      _loadingStats = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      // Get upcoming training sessions
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      QuerySnapshot upcomingSessionsSnapshot = await _firestore
          .collection('training_sessions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      // Get total students count
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // Get current week from active training course
      String currentWeek = 'N/A';
      try {
        QuerySnapshot courseSnapshot = await _firestore
            .collection('training_courses')
            .where('coachId', isEqualTo: user.uid)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (courseSnapshot.docs.isNotEmpty) {
          DocumentSnapshot doc = courseSnapshot.docs.first;
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          DateTime startDate = (data['startDate'] as Timestamp).toDate();
          DateTime currentDate = DateTime.now();
          int daysSinceStart = currentDate.difference(startDate).inDays;
          int weekNumber = (daysSinceStart / 7).floor() + 1;

          currentWeek = 'Week $weekNumber';
        }
      } catch (e) {
        print('Error getting current week: $e');
        currentWeek = 'No Course';
      }

      setState(() {
        _upcomingSessions = upcomingSessionsSnapshot.docs.length;
        _totalStudents = studentsSnapshot.docs.length;
        _currentWeek = currentWeek;
        _loadingStats = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _loadingStats = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SplashScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    final String userId = user?.uid ?? '';

    return Scaffold(
      // CHANGED: Added blue gradient background container
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6).withOpacity(0.1), // CHANGED: Light blue fade at top
              Colors.white,                        // CHANGED: White at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E40AF),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sport-inspired Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1E40AF),
                              Color(0xFF3B82F6),
                              Color(0xFF60A5FA)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF3B82F6).withOpacity(0.4),
                              blurRadius: 25,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          'COACH DASHBOARD',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _fullName.isNotEmpty
                                            ? _fullName
                                            : 'Coach $_username',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Sepak Takraw Training',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Profile button with sport styling
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TeacherProfilePage(
                                              onProfileUpdated: _loadUserData,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.15),
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: _profileImageUrl.isNotEmpty
                                              ? Image.network(_profileImageUrl,
                                                  fit: BoxFit.cover)
                                              : Icon(
                                                  Icons.sports,
                                                  color: Color(0xFF3B82F6),
                                                  size: 24,
                                                ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    // Logout button
                                    GestureDetector(
                                      onTap: () => _signOut(context),
                                      child: Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFEF4444),
                                              Color(0xFFDC2626)
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFFEF4444)
                                                  .withOpacity(0.4),
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.logout,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            // Dynamic quick stats with sport styling
                            Row(
                              children: [
                                _buildSportStat(
                                  _loadingStats
                                      ? '...'
                                      : '$_upcomingSessions',
                                  'Sessions',
                                  Color(0xFFFF6B35),
                                ),
                                SizedBox(width: 16),
                                _buildSportStat(
                                  _loadingStats
                                      ? '...'
                                      : '$_totalStudents',
                                  'Athletes',
                                  Color(0xFF10B981),
                                ),
                                SizedBox(width: 16),
                                _buildSportStat(
                                  _loadingStats
                                      ? '...'
                                      : _currentWeek,
                                  'Current',
                                  Color(0xFFF59E0B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Content with sport elements
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Consolidated Management Tools Section
                            _buildSectionTitle('Management Tools'),
                            SizedBox(height: 16),

                            // Unified card grid for all functions
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.1,
                              children: [
                                _buildUnifiedCard(
                                  'TRAINING',
                                  Icons.play_circle_filled,
                                  Color(0xFF10B981),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TrainingPage(
                                          userId: userId,
                                          displayName: _username,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildUnifiedCard(
                                  'GAME BOARD',
                                  Icons.scoreboard,
                                  Color(0xFFF59E0B),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SepakTakrawApp(),
                                      ),
                                    );
                                  },
                                ),
                                _buildUnifiedCard(
                                  'SCHEDULE',
                                  Icons.calendar_month,
                                 Color(0xFF3B82F6),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ScheduleListScreen(
                                          userId: userId,
                                        ),
                                      ),
                                    ).then((_) {
                                      _loadStatistics();
                                    });
                                  },
                                ),
                                _buildUnifiedCard(
                                  'NEW SESSION',
                                  Icons.add_circle,
                                  Color(0xFF8B5CF6),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ScheduleDateScreen(
                                          userId: userId,
                                        ),
                                      ),
                                    ).then((_) {
                                      _loadStatistics();
                                    });
                                  },
                                ),
                              ],
                            ),

                            SizedBox(height: 24),

                            // Performance Analytics Card
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GenerateReportPage(
                                      coachId: userId,
                                      coachName: _fullName.isNotEmpty
                                          ? _fullName
                                          : _username,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF6366F1).withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.assessment,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Performance Reports',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Generate athlete progress analysis',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSportStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1F2937),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildUnifiedCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}