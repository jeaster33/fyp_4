import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TrainingRecordViewTeacher extends StatefulWidget {
  final String coachId;
  final String coachName;

  const TrainingRecordViewTeacher({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  _TrainingRecordViewTeacherState createState() => _TrainingRecordViewTeacherState();
}

class _TrainingRecordViewTeacherState extends State<TrainingRecordViewTeacher> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _trainingRecords = [];
  Map<String, String> _studentNames = {};
  final Map<String, bool> _showCharts = {};
  
  @override
  void initState() {
    super.initState();
    _loadTrainingRecords();
  }
  
  Future<void> _loadTrainingRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all training records across different collections
      List<Map<String, dynamic>> allRecords = [];
      Set<String> studentIds = {};
      
      // Get stamina records
      QuerySnapshot staminaSnapshot = await _firestore
          .collection('stamina_records')
          .where('coachId', isEqualTo: widget.coachId)
          .get();
          
      for (var doc in staminaSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('studentId')) {
          studentIds.add(data['studentId']);
        }
        
        // Parse time string to seconds for comparisons
        String timeString = data['time'] ?? '00:00.0';
        int totalSeconds = _parseTimeToSeconds(timeString);
        
        allRecords.add({
          'id': doc.id,
          'recordType': 'Stamina Training',
          'score': 0, // No direct score for stamina
          'time': timeString,
          'totalSeconds': totalSeconds,
          ...data,
        });
      }
      
      // Get balance records - UPDATED for juggling count
      QuerySnapshot balanceSnapshot = await _firestore
          .collection('balance_records')
          .where('coachId', isEqualTo: widget.coachId)
          .get();
          
      for (var doc in balanceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('studentId')) {
          studentIds.add(data['studentId']);
        }
        
        // CHANGED: Use juggling count instead of balance score
        int jugglingCount = data['jugglingCount'] ?? data['balanceScore'] ?? 0;
        
        allRecords.add({
          'id': doc.id,
          'recordType': 'Balance Training',
          'jugglingCount': jugglingCount, // ADDED: Store juggling count
          'score': jugglingCount, // For compatibility with existing chart code
          ...data,
        });
      }
      
      // Get spike records
      QuerySnapshot spikeSnapshot = await _firestore
          .collection('spike_records')
          .where('coachId', isEqualTo: widget.coachId)
          .get();
          
      for (var doc in spikeSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('studentId')) {
          studentIds.add(data['studentId']);
        }
        
        // Calculate a score from successful spikes percentage
        int successfulSpikes = data['successfulSpikes'] ?? 0;
        int totalAttempts = data['totalAttempts'] ?? 1; // Avoid division by zero
        double successRate = totalAttempts > 0 ? successfulSpikes / totalAttempts : 0;
        int score = (successRate * 10).round();
        
        allRecords.add({
          'id': doc.id,
          'recordType': 'Spike Training',
          'score': score,
          'successRate': successRate,
          ...data,
        });
      }
      
      // Get any other general training records
      QuerySnapshot trainingSnapshot = await _firestore
          .collection('training_records')
          .where('coachId', isEqualTo: widget.coachId)
          .get();
          
      for (var doc in trainingSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('studentId')) {
          studentIds.add(data['studentId']);
        }
        allRecords.add({
          'id': doc.id,
          'recordType': 'General Training',
          ...data,
        });
      }
      
      // Get all student names in one batch
      if (studentIds.isNotEmpty) {
        Map<String, String> studentNames = {};
        for (String studentId in studentIds) {
          DocumentSnapshot studentDoc = await _firestore
              .collection('users')
              .doc(studentId)
              .get();
          
          if (studentDoc.exists) {
            Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
            String fullName = studentData['fullName'] ?? 'Unknown';
            studentNames[studentId] = fullName;
            _showCharts[studentId] = false; // Initialize chart visibility
          } else {
            studentNames[studentId] = 'Unknown Student';
            _showCharts[studentId] = false;
          }
        }
        
        setState(() {
          _studentNames = studentNames;
        });
      }
      
      setState(() {
        _trainingRecords = allRecords;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading training records: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading training records')),
      );
    }
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
    // Group records by student
    Map<String, List<Map<String, dynamic>>> recordsByStudent = {};
    
    for (var record in _trainingRecords) {
      final studentId = record['studentId'] ?? '';
      if (!recordsByStudent.containsKey(studentId)) {
        recordsByStudent[studentId] = [];
      }
      recordsByStudent[studentId]!.add(record);
    }
    
    // Sort students by name
    List<String> sortedStudentIds = recordsByStudent.keys.toList();
    sortedStudentIds.sort((a, b) => 
      (_studentNames[a] ?? '').compareTo(_studentNames[b] ?? ''));
    
    return Scaffold(
      // ENHANCED: Gradient app bar
      appBar: AppBar(
        title: Text(
          'Training Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E40AF),
                Color(0xFF3B82F6),
                Color(0xFF60A5FA),
              ],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      // ENHANCED: Gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ENHANCED: Beautiful loading spinner
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
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Loading training records...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _trainingRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ENHANCED: Beautiful empty state
                        Container(
                          padding: EdgeInsets.all(40),
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
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.sports_score, 
                                  size: 60, 
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'No training records found',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start a training session to record\nplayer performance',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: sortedStudentIds.length,
                    itemBuilder: (context, index) {
                      final studentId = sortedStudentIds[index];
                      final studentName = _studentNames[studentId] ?? 'Unknown Student';
                      final studentRecords = recordsByStudent[studentId] ?? [];
                      
                      // Sort records by date (newest first)
                      studentRecords.sort((a, b) {
                        final aTimestamp = a['timestamp'] as Timestamp?;
                        final bTimestamp = b['timestamp'] as Timestamp?;
                        if (aTimestamp == null || bTimestamp == null) return 0;
                        return bTimestamp.compareTo(aTimestamp);
                      });
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
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
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.all(20),
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              studentName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            subtitle: Container(
                              margin: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6).withOpacity(0.1),
                                          Color(0xFF1E40AF).withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Color(0xFF3B82F6).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${studentRecords.length} training records',
                                      style: TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            leading: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF1E40AF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF3B82F6).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            onExpansionChanged: (isExpanded) {
                              if (isExpanded) {
                                setState(() {
                                  _showCharts[studentId] = false;
                                });
                              }
                            },
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.grey.shade50,
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Student summary statistics
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Training type summaries
                                          _buildStudentSummary(studentRecords),
                                          SizedBox(height: 20),
                                          
                                          // Toggle charts button
                                          Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFF3B82F6),
                                                    Color(0xFF1E40AF),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0xFF3B82F6).withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                icon: Icon(_showCharts[studentId] == true 
                                                    ? Icons.visibility_off 
                                                    : Icons.bar_chart),
                                                label: Text(_showCharts[studentId] == true 
                                                    ? 'Hide Charts' 
                                                    : 'Show Performance Charts'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  foregroundColor: Colors.white,
                                                  shadowColor: Colors.transparent,
                                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _showCharts[studentId] = !(_showCharts[studentId] ?? false);
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          
                                          // Performance charts (when toggled)
                                          if (_showCharts[studentId] == true)
                                            Column(
                                              children: [
                                                _buildPerformanceCharts(studentRecords),
                                                SizedBox(height: 20),
                                              ],
                                            ),
                                          
                                          // Record list header
                                          Container(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Color(0xFF10B981),
                                                        Color(0xFF059669),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.history,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Training History',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 2,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF3B82F6).withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Individual training records
                                    ...studentRecords.map((record) {
                                      final timestamp = record['timestamp'] as Timestamp?;
                                      final dateTime = timestamp?.toDate() ?? DateTime.now();
                                      final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
                                      
                                      return Container(
                                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          title: Text(
                                            record['drillName'] ?? record['recordType'] ?? 'Unknown Drill',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          subtitle: Container(
                                            margin: EdgeInsets.only(top: 4),
                                            child: Text(
                                              formattedDate,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          trailing: _buildTrailingWidget(record),
                                          onTap: () {
                                            _showRecordDetails(context, record, studentName);
                                          },
                                        ),
                                      );
                                    }),
                                    SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
  
  Widget _buildStudentSummary(List<Map<String, dynamic>> records) {
    // Count record types
    int balanceCount = 0;
    int spikeCount = 0;
    int staminaCount = 0;
    int generalCount = 0;
    
    // Performance metrics - UPDATED for juggling count
    double avgJugglingCount = 0;
    int bestJugglingCount = 0;
    double avgSpikeRate = 0;
    double bestSpikeRate = 0;
    String bestStaminaTime = '00:00.0';
    int bestStaminaSeconds = 9999;
    
    List<Map<String, dynamic>> balanceRecords = [];
    List<Map<String, dynamic>> spikeRecords = [];
    List<Map<String, dynamic>> staminaRecords = [];
    
    for (var record in records) {
      String recordType = record['recordType'] ?? '';
      
      if (recordType == 'Balance Training') {
        balanceCount++;
        balanceRecords.add(record);
        // CHANGED: Use juggling count instead of score
        int jugglingCount = record['jugglingCount'] ?? record['balanceScore'] ?? 0;
        avgJugglingCount += jugglingCount;
        if (jugglingCount > bestJugglingCount) bestJugglingCount = jugglingCount;
      } 
      else if (recordType == 'Spike Training') {
        spikeCount++;
        spikeRecords.add(record);
        double rate = record['successRate'] ?? 0.0;
        avgSpikeRate += rate;
        if (rate > bestSpikeRate) bestSpikeRate = rate;
      } 
      else if (recordType == 'Stamina Training') {
        staminaCount++;
        staminaRecords.add(record);
        int seconds = record['totalSeconds'] ?? 0;
        if (seconds > 0 && seconds < bestStaminaSeconds) {
          bestStaminaSeconds = seconds;
          bestStaminaTime = record['time'] ?? '00:00.0';
        }
      } 
      else {
        generalCount++;
      }
    }
    
    // Calculate averages
    if (balanceCount > 0) avgJugglingCount /= balanceCount;
    if (spikeCount > 0) avgSpikeRate /= spikeCount;
    
    // Summary cards
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF7C3AED),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Performance Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        
        // Balance summary (if applicable) - UPDATED for juggling count
        if (balanceCount > 0) 
          _buildSummaryCard(
            'Balance',
            '$balanceCount sessions',
            [
              {'label': 'Best Juggles', 'value': '$bestJugglingCount'}, // CHANGED
              {'label': 'Avg Juggles', 'value': avgJugglingCount.toStringAsFixed(1)}, // CHANGED
              {'label': 'Latest', 'value': '${balanceRecords.first['jugglingCount'] ?? balanceRecords.first['balanceScore'] ?? 0}'}, // CHANGED
            ],
            Colors.green,
            Icons.sports_handball // CHANGED icon
          ),
          
        if (balanceCount > 0) SizedBox(height: 12),
          
        // Spike summary (if applicable)
        if (spikeCount > 0) 
          _buildSummaryCard(
            'Spike',
            '$spikeCount sessions',
            [
              {'label': 'Best Rate', 'value': '${(bestSpikeRate * 100).toStringAsFixed(1)}%'},
              {'label': 'Avg Rate', 'value': '${(avgSpikeRate * 100).toStringAsFixed(1)}%'},
              {'label': 'Latest', 'value': '${(spikeRecords.first['successRate'] ?? 0.0 * 100).toStringAsFixed(1)}%'},
            ],
            Colors.purple,
            Icons.sports_volleyball
          ),
          
        if (spikeCount > 0) SizedBox(height: 12),
          
        // Stamina summary (if applicable)
        if (staminaCount > 0) 
          _buildSummaryCard(
            'Stamina',
            '$staminaCount sessions',
            [
              {'label': 'Best Time', 'value': bestStaminaTime},
              {'label': 'Latest', 'value': staminaRecords.first['time'] ?? '00:00.0'},
              {'label': 'Total', 'value': '$staminaCount runs'},
            ],
            Colors.blue,
            Icons.timer
          ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String subtitle,
    List<Map<String, String>> stats,
    Color color,
    IconData icon
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
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
                        '$title Training',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats.map((stat) => _buildStatItem(
                stat['label']!,
                stat['value']!,
                color
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPerformanceCharts(List<Map<String, dynamic>> records) {
    // Filter records by type
    List<Map<String, dynamic>> balanceRecords = records
        .where((r) => r['recordType'] == 'Balance Training')
        .toList();
        
    List<Map<String, dynamic>> spikeRecords = records
        .where((r) => r['recordType'] == 'Spike Training')
        .toList();
        
    List<Map<String, dynamic>> staminaRecords = records
        .where((r) => r['recordType'] == 'Stamina Training')
        .toList();
    
    // Sort records by date (oldest first for timeline)
    for (var recordList in [balanceRecords, spikeRecords, staminaRecords]) {
      recordList.sort((a, b) {
        final aTimestamp = a['timestamp'] as Timestamp?;
        final bTimestamp = b['timestamp'] as Timestamp?;
        if (aTimestamp == null || bTimestamp == null) return 0;
        return aTimestamp.compareTo(bTimestamp);
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance chart - UPDATED for juggling count
        if (balanceRecords.length > 1)
          Container(
            margin: EdgeInsets.only(bottom: 24),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.sports_handball, color: Colors.white, size: 16),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Juggling Count Progress', // CHANGED title
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildLineChart(
                    balanceRecords,
                    (record) => (record['jugglingCount'] ?? record['balanceScore'] ?? 0).toDouble(), // CHANGED to use juggling count
                    Colors.green,
                    0,
                    null, // Auto max for juggling count
                  ),
                ),
              ],
            ),
          ),
          
        // Spike chart
        if (spikeRecords.length > 1)
          Container(
            margin: EdgeInsets.only(bottom: 24),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.purple.shade700],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.sports_volleyball, color: Colors.white, size: 16),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Spike Success Rate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildLineChart(
                    spikeRecords,
                    (record) => (record['successRate'] ?? 0.0).toDouble(),
                    Colors.purple,
                    0,
                    1.0,
                    isPercentage: true
                  ),
                ),
              ],
            ),
          ),
          
        // Stamina chart
        if (staminaRecords.length > 1)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blue.shade700],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.timer, color: Colors.white, size: 16),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Stamina Time Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildLineChart(
                    staminaRecords,
                    (record) => (record['totalSeconds'] ?? 0).toDouble(),
                    Colors.blue,
                    0,
                    null, // Auto max
                    reverse: true, // Lower is better
                    timeFormat: true
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildLineChart(
    List<Map<String, dynamic>> records,
    double Function(Map<String, dynamic>) getValue,
    Color color,
    double minY,
    double? maxY, {
    bool isPercentage = false,
    bool reverse = false,
    bool timeFormat = false,
  }) {
    // Calculate max if not provided
    if (maxY == null) {
      maxY = 0;
      for (var record in records) {
        double value = getValue(record);
        if (value > maxY!) maxY = value;
      }
      maxY = (maxY ?? 0) * 1.2; // Add some padding
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: timeFormat ? 60 : (maxY > 10 ? 30 : 1),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (timeFormat) {
                  int minutes = (value / 60).floor();
                  int seconds = (value % 60).floor();
                  return Text('$minutes:${seconds.toString().padLeft(2, '0')}');
                } else if (isPercentage) {
                  return Text('${(value * 100).toInt()}%');
                } else {
                  return Text('${value.toInt()}'); // CHANGED: Show as integer for juggling count
                }
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                try {
                  var index = value.toInt();
                  if (index >= 0 && index < records.length && index % 3 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('W${index + 1}'),
                    );
                  }
                } catch (_) {}
                return Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        minX: 0,
        maxX: records.length.toDouble() - 1,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              records.length,
              (i) => FlSpot(i.toDouble(), getValue(records[i])),
            ),
            isCurved: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: color,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true, 
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrailingWidget(Map<String, dynamic> record) {
    String recordType = record['recordType'] ?? '';
    
    if (recordType == 'Balance Training') {
      // CHANGED: Show juggling count instead of score/10
      int jugglingCount = record['jugglingCount'] ?? record['balanceScore'] ?? 0;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getJugglingCountColor(jugglingCount),
              _getJugglingCountColor(jugglingCount).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getJugglingCountColor(jugglingCount).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$jugglingCount juggles', // CHANGED display format
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    } 
    else if (recordType == 'Spike Training') {
      double successRate = record['successRate'] ?? 0.0;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getSpikeRateColor(successRate),
              _getSpikeRateColor(successRate).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getSpikeRateColor(successRate).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${(successRate * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    else if (recordType == 'Stamina Training') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          record['time'] ?? '00:00',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getScoreColor(record['score']),
              _getScoreColor(record['score']).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getScoreColor(record['score']).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${record['score'] ?? 'N/A'}/10',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  // ADDED: New color function for juggling count
  Color _getJugglingCountColor(int count) {
    if (count >= 50) return Colors.green;
    if (count >= 30) return Colors.lightGreen;
    if (count >= 20) return Colors.orange;
    if (count >= 10) return Colors.deepOrange;
    return Colors.red;
  }

  Color _getScoreColor(dynamic score) {
    if (score == null) return Colors.grey;
    
    int scoreValue = score is int ? score : int.tryParse(score.toString()) ?? 0;
    
    if (scoreValue >= 8) return Colors.green;
    if (scoreValue >= 6) return Colors.blue;
    if (scoreValue >= 4) return Colors.orange;
    return Colors.red;
  }
  
  Color _getSpikeRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.lightGreen;
    if (rate >= 0.4) return Colors.orange;
    if (rate >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }

  void _showRecordDetails(BuildContext context, Map<String, dynamic> record, String studentName) {
    final timestamp = record['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy - h:mm a').format(dateTime);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, -10),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF1E40AF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Training Record Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Student', studentName),
                    _buildDetailRow('Training Type', record['drillName'] ?? record['recordType'] ?? 'Unknown'),
                    _buildDetailRow('Date & Time', formattedDate),
                    _buildDetailRow('Week', record['selectedWeek']?.toString() ?? record['weekTimestamp']?.toString() ?? 'N/A'),
                    
                    // Type-specific details - UPDATED for balance training
                    if (record['recordType'] == 'Balance Training') ...[
                      _buildDetailRow('Juggling Count', '${record['jugglingCount'] ?? record['balanceScore'] ?? 0} juggles'), // CHANGED
                    ],
                    
                    // For spike training, show additional details
                    if (record['recordType'] == 'Spike Training') ...[
                      _buildDetailRow('Success Rate', 
                        '${(record['successRate'] * 100).toStringAsFixed(1)}%'),
                      _buildDetailRow('Attempts', 
                        '${record['successfulSpikes'] ?? 0}/${record['totalAttempts'] ?? 0} spikes'),
                    ],
                    
                    // For stamina training, show time
                    if (record['recordType'] == 'Stamina Training')
                      _buildDetailRow('Time', record['time'] ?? 'N/A'),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade50,
                      Colors.grey.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Coach Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      record['notes'] ?? 'No notes provided',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF1E40AF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}