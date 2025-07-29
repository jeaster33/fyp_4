import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RankingTrainingPage extends StatefulWidget {
  const RankingTrainingPage({super.key});

  @override
  State<RankingTrainingPage> createState() => _RankingTrainingPageState();
}

class _RankingTrainingPageState extends State<RankingTrainingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  String _currentWeek = 'N/A';
  String _currentUserId = '';
  
  List<Map<String, dynamic>> _staminaRankings = [];
  List<Map<String, dynamic>> _spikeRankings = [];
  List<Map<String, dynamic>> _balanceRankings = [];
  
  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    _loadCurrentWeekRankings();
  }
  
  Future<void> _loadCurrentWeekRankings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current week information
      String currentWeek = await _getCurrentWeek();
      setState(() {
        _currentWeek = currentWeek;
      });
      
      // Load rankings for all training types
      await Future.wait([
        _loadStaminaRankings(currentWeek),
        _loadSpikeRankings(currentWeek),
        _loadBalanceRankings(currentWeek),
      ]);
      
    } catch (e) {
      print('Error loading rankings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<String> _getCurrentWeek() async {
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
        
        return 'Week $weekNumber';
      }
    } catch (e) {
      print('Error getting current week: $e');
    }
    return 'Week 1';
  }
  
  Future<void> _loadStaminaRankings(String currentWeek) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('stamina_records')
          .where('weekTimestamp', isEqualTo: currentWeek)
          .get();
      
      Map<String, Map<String, dynamic>> userBestTimes = {};
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String studentId = data['studentId'] ?? '';
        String timeString = data['time'] ?? '00:00.0';
        int totalSeconds = _parseTimeToSeconds(timeString);
        
        if (studentId.isNotEmpty) {
          if (!userBestTimes.containsKey(studentId) || 
              totalSeconds < userBestTimes[studentId]!['totalSeconds']) {
            
            // Get student name
            String studentName = await _getStudentName(studentId);
            
            userBestTimes[studentId] = {
              'studentId': studentId,
              'studentName': studentName,
              'time': timeString,
              'totalSeconds': totalSeconds,
              'courseName': data['courseName'] ?? 'Unknown',
            };
          }
        }
      }
      
      List<Map<String, dynamic>> rankings = userBestTimes.values.toList();
      rankings.sort((a, b) => a['totalSeconds'].compareTo(b['totalSeconds']));
      
      setState(() {
        _staminaRankings = rankings.take(10).toList();
      });
    } catch (e) {
      print('Error loading stamina rankings: $e');
    }
  }
  
  Future<void> _loadSpikeRankings(String currentWeek) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('spike_records')
          .where('weekTimestamp', isEqualTo: currentWeek)
          .get();
      
      Map<String, Map<String, dynamic>> userBestRates = {};
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String studentId = data['studentId'] ?? '';
        double successRate = (data['successRate'] ?? 0.0).toDouble();
        
        if (studentId.isNotEmpty) {
          if (!userBestRates.containsKey(studentId) || 
              successRate > userBestRates[studentId]!['successRate']) {
            
            // Get student name
            String studentName = await _getStudentName(studentId);
            
            userBestRates[studentId] = {
              'studentId': studentId,
              'studentName': studentName,
              'successRate': successRate,
              'successfulSpikes': data['successfulSpikes'] ?? 0,
              'totalAttempts': data['totalAttempts'] ?? 0,
              'courseName': data['courseName'] ?? 'Unknown',
            };
          }
        }
      }
      
      List<Map<String, dynamic>> rankings = userBestRates.values.toList();
      rankings.sort((a, b) => b['successRate'].compareTo(a['successRate']));
      
      setState(() {
        _spikeRankings = rankings.take(10).toList();
      });
    } catch (e) {
      print('Error loading spike rankings: $e');
    }
  }
  
  Future<void> _loadBalanceRankings(String currentWeek) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('balance_records')
          .where('weekTimestamp', isEqualTo: currentWeek)
          .get();
      
      Map<String, Map<String, dynamic>> userBestCounts = {};
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String studentId = data['studentId'] ?? '';
        int jugglingCount = data['jugglingCount'] ?? data['balanceScore'] ?? 0;
        
        if (studentId.isNotEmpty) {
          if (!userBestCounts.containsKey(studentId) || 
              jugglingCount > userBestCounts[studentId]!['jugglingCount']) {
            
            // CHANGED: Get both full name and username for balance rankings
            Map<String, String> studentInfo = await _getStudentInfo(studentId);
            
            userBestCounts[studentId] = {
              'studentId': studentId,
              'studentName': studentInfo['fullName'] ?? 'Unknown Student',
              'username': studentInfo['username'] ?? 'unknown', // ADDED: Store username separately
              'jugglingCount': jugglingCount,
              'courseName': data['courseName'] ?? 'Unknown',
            };
          }
        }
      }
      
      List<Map<String, dynamic>> rankings = userBestCounts.values.toList();
      rankings.sort((a, b) => b['jugglingCount'].compareTo(a['jugglingCount']));
      
      setState(() {
        _balanceRankings = rankings.take(10).toList();
      });
    } catch (e) {
      print('Error loading balance rankings: $e');
    }
  }
  
  Future<String> _getStudentName(String studentId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(studentId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['fullName'] ?? userData['username'] ?? 'Unknown Student';
      }
    } catch (e) {
      print('Error getting student name: $e');
    }
    return 'Unknown Student';
  }

  // ADDED: New method to get both full name and username
  Future<Map<String, String>> _getStudentInfo(String studentId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(studentId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return {
          'fullName': userData['fullName'] ?? 'Unknown Student',
          'username': userData['username'] ?? 'unknown',
        };
      }
    } catch (e) {
      print('Error getting student info: $e');
    }
    return {
      'fullName': 'Unknown Student',
      'username': 'unknown',
    };
  }
  
  int _parseTimeToSeconds(String timeString) {
    try {
      List<String> parts = timeString.split(':');
      if (parts.length != 2) return 0;
      
      int minutes = int.parse(parts[0]);
      double seconds = double.parse(parts[1]);
      return (minutes * 60) + seconds.toInt();
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Training Rankings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B35),
                Color(0xFFFF8C42),
                Color(0xFFFFAD5A),
              ],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCurrentWeekRankings,
            tooltip: 'Refresh Rankings',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF6B35).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Loading rankings...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeekHeader(),
                    SizedBox(height: 24),
                    _buildRankingSection(
                      'Stamina Training', 
                      'Best Times (Lower is Better)',
                      Icons.timer,
                      Color(0xFF3B82F6),
                      _staminaRankings,
                      'stamina',
                    ),
                    SizedBox(height: 24),
                    _buildRankingSection(
                      'Spike Training', 
                      'Success Rates (Higher is Better)',
                      Icons.sports_volleyball,
                      Color(0xFF8B5CF6),
                      _spikeRankings,
                      'spike',
                    ),
                    SizedBox(height: 24),
                    _buildRankingSection(
                      'Balance Training', 
                      'Juggling Counts (Higher is Better)',
                      Icons.sports_handball,
                      Color(0xFF10B981),
                      _balanceRankings,
                      'balance',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildWeekHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.leaderboard, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Week Rankings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _currentWeek,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRankingSection(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> rankings,
    String type,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (rankings.isEmpty)
            Container(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(icon, size: 40, color: Colors.grey.shade400),
                    SizedBox(height: 12),
                    Text(
                      'No records found for $_currentWeek',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: rankings.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> student = entry.value;
                return _buildRankingItem(student, index + 1, type, color);
              }).toList(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildRankingItem(Map<String, dynamic> student, int rank, String type, Color color) {
    bool isCurrentUser = student['studentId'] == _currentUserId;
    
    String displayValue = '';
    String subtitle = '';
    
    switch (type) {
      case 'stamina':
        displayValue = student['time'] ?? '00:00.0';
        subtitle = 'Course: ${student['courseName']}';
        break;
      case 'spike':
        double rate = student['successRate'] ?? 0.0;
        displayValue = '${(rate * 100).toStringAsFixed(1)}%';
        subtitle = '${student['successfulSpikes']}/${student['totalAttempts']} spikes';
        break;
      case 'balance':
        displayValue = '${student['jugglingCount']} juggles';
        subtitle = 'Course: ${student['courseName']}';
        break;
    }
    
    // CHANGED: Use username for balance training instead of full name to prevent overflow
    String displayName = student['studentName'] ?? 'Unknown Student';
    if (type == 'balance' && student.containsKey('username')) {
      displayName = student['username'] ?? student['studentName'] ?? 'Unknown Student';
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: rank <= 3 
                  ? (rank == 1 ? [Colors.amber, Colors.amber.shade600]
                     : rank == 2 ? [Colors.grey.shade400, Colors.grey.shade600]
                     : [Colors.brown.shade300, Colors.brown.shade500])
                  : [color.withOpacity(0.3), color.withOpacity(0.5)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                ? Icon(
                    rank == 1 ? Icons.emoji_events : Icons.military_tech,
                    color: Colors.white,
                    size: 20,
                  )
                : Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // CHANGED: Use Flexible to prevent overflow and show ellipsis
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? color : Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis, // ADDED: Handle text overflow
                        maxLines: 1, // ADDED: Limit to one line
                      ),
                    ),
                    if (isCurrentUser) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}