import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../authentication page/splash_screen.dart';
import 'profile_page.dart';
import 'performance_page.dart';
import 'ranking_training__page.dart';
import 'student_schedule_list_screen.dart';
import 'attendance_student_page.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _fullName = 'Athlete';
  String _username = '';
  String _profileImageUrl = '';
  bool _isLoading = true;

  // Dynamic statistics variables
  int _upcomingSessions = 0;
  String _attendancePercentage = '0%';
  String _currentWeek = 'N/A';
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStudentStatistics();
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
            _fullName = data['fullName'] ?? 'Athlete';
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

  Future<void> _loadStudentStatistics() async {
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

      // Get attendance records for this student
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance_records')
          .where('studentId', isEqualTo: user.uid)
          .get();

      // Calculate attendance percentage
      double attendanceRate = 0.0;
      if (attendanceSnapshot.docs.isNotEmpty) {
        int presentCount = 0;
        int totalSessions = attendanceSnapshot.docs.length;

        for (var doc in attendanceSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data['present'] == true) {
            presentCount++;
          }
        }

        attendanceRate = (presentCount / totalSessions) * 100;
      }

      // Smart percentage formatting for attendance
      String formattedAttendance;
      if (attendanceRate == 100.0) {
        formattedAttendance = '100%';
      } else if (attendanceRate % 1 == 0) {
        formattedAttendance = '${attendanceRate.toInt()}%';
      } else {
        formattedAttendance = '${attendanceRate.toStringAsFixed(1)}%';
      }

      // Get current week from active training course
      String currentWeek = 'N/A';
      try {
        QuerySnapshot courseSnapshot = await _firestore
            .collection('training_courses')
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
        _attendancePercentage = formattedAttendance;
        _currentWeek = currentWeek;
        _loadingStats = false;
      });
    } catch (e) {
      print('Error loading student statistics: $e');
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
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF10B981).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
              ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF059669),
                              Color(0xFF047857)
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
                              color: Color(0xFF10B981).withOpacity(0.4),
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
                                          'ATHLETE DASHBOARD',
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
                                            : 'Athlete $_username',
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
                                    // Profile button
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
                                                  Icons.sports_handball,
                                                  color: Color(0xFF10B981),
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

                            // Dynamic quick stats
                            Row(
                              children: [
                                _buildSportStat(
                                  _loadingStats ? '...' : '$_upcomingSessions',
                                  'Sessions',
                                  Color(0xFFFF6B35),
                                ),
                                SizedBox(width: 16),
                                _buildSportStat(
                                  _loadingStats ? '...' : _attendancePercentage,
                                  'Attendance',
                                  Color(0xFF3B82F6),
                                ),
                                SizedBox(width: 16),
                                _buildSportStat(
                                  _loadingStats ? '...' : _currentWeek,
                                  'Current',
                                  Color(0xFFF59E0B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Training Tools Section
                            _buildSectionTitle('Training Tools'),
                            SizedBox(height: 16),

                            // 2x2 Grid
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.1,
                              children: [
                                _buildUnifiedCard(
                                  'PROFILE',
                                  Icons.account_circle,
                                  Color(0xFF10B981),
                                  () {
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
                                _buildUnifiedCard(
                                  'PERFORMANCE',
                                  Icons.insights,
                                  Color(0xFFF59E0B),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PerformancePage()),
                                    );
                                  },
                                ),
                                _buildUnifiedCard(
                                  'SCHEDULE',
                                  Icons.calendar_today,
                                  Color(0xFF3B82F6),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StudentScheduleListScreen(
                                          userId: _auth.currentUser?.uid ?? '',
                                        ),
                                      ),
                                    ).then((_) {
                                      _loadStudentStatistics();
                                    });
                                  },
                                ),
                                _buildUnifiedCard(
                                  'ATTENDANCE',
                                  Icons.fact_check,
                                  Color(0xFF8B5CF6),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AttendanceStudentPage(),
                                      ),
                                    ).then((_) {
                                      _loadStudentStatistics();
                                    });
                                  },
                                ),
                              ],
                            ),

                            SizedBox(height: 24),

                            // Rankings Card
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RankingTrainingPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B35),
                                      Color(0xFFFF8C42),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFFF6B35).withOpacity(0.4),
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
                                        Icons.leaderboard,
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
                                            'Training Rankings',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'See who\'s leading this week\'s training',
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