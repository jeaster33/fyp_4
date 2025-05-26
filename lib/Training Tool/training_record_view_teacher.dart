import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TrainingRecordViewTeacher extends StatefulWidget {
  final String coachId;
  final String coachName;

  const TrainingRecordViewTeacher({
    Key? key,
    required this.coachId,
    required this.coachName,
  }) : super(key: key);

  @override
  _TrainingRecordViewTeacherState createState() => _TrainingRecordViewTeacherState();
}

class _TrainingRecordViewTeacherState extends State<TrainingRecordViewTeacher> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _trainingRecords = [];
  Map<String, String> _studentNames = {};
  Map<String, bool> _showCharts = {};
  
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
      
      // Get balance records
      QuerySnapshot balanceSnapshot = await _firestore
          .collection('balance_records')
          .where('coachId', isEqualTo: widget.coachId)
          .get();
          
      for (var doc in balanceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('studentId')) {
          studentIds.add(data['studentId']);
        }
        allRecords.add({
          'id': doc.id,
          'recordType': 'Balance Training',
          'score': data['balanceScore'] ?? 0,
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
      appBar: AppBar(
        title: Text('Training Records'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _trainingRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_score, size: 80, color: Colors.grey.shade300),
                      SizedBox(height: 16),
                      Text(
                        'No training records found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start a training session to record player performance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          studentName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text('${studentRecords.length} training records'),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            Icons.person,
                            color: Colors.blue,
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
                          // Student summary statistics
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Training type summaries
                                _buildStudentSummary(studentRecords),
                                SizedBox(height: 16),
                                
                                // Toggle charts button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: Icon(_showCharts[studentId] == true 
                                          ? Icons.visibility_off 
                                          : Icons.bar_chart),
                                      label: Text(_showCharts[studentId] == true 
                                          ? 'Hide Charts' 
                                          : 'Show Performance Charts'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showCharts[studentId] = !(_showCharts[studentId] ?? false);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                
                                // Performance charts (when toggled)
                                if (_showCharts[studentId] == true)
                                  Column(
                                    children: [
                                      _buildPerformanceCharts(studentRecords),
                                      SizedBox(height: 16),
                                    ],
                                  ),
                                
                                // Record list header
                                Text(
                                  'Training History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(),
                              ],
                            ),
                          ),
                          
                          // Individual training records
                          ...studentRecords.map((record) {
                            final timestamp = record['timestamp'] as Timestamp?;
                            final dateTime = timestamp?.toDate() ?? DateTime.now();
                            final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
                            
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              title: Text(
                                record['drillName'] ?? record['recordType'] ?? 'Unknown Drill',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(formattedDate),
                              trailing: _buildTrailingWidget(record),
                              onTap: () {
                                _showRecordDetails(context, record, studentName);
                              },
                            );
                          }).toList(),
                          SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
  
  Widget _buildStudentSummary(List<Map<String, dynamic>> records) {
    // Count record types
    int balanceCount = 0;
    int spikeCount = 0;
    int staminaCount = 0;
    int generalCount = 0;
    
    // Performance metrics
    double avgBalanceScore = 0;
    double bestBalanceScore = 0;
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
        int score = record['score'] ?? 0;
        avgBalanceScore += score;
        if (score > bestBalanceScore) bestBalanceScore = score.toDouble();
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
    if (balanceCount > 0) avgBalanceScore /= balanceCount;
    if (spikeCount > 0) avgSpikeRate /= spikeCount;
    
    // Summary cards
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        // Balance summary (if applicable)
        if (balanceCount > 0) 
          _buildSummaryCard(
            'Balance',
            '${balanceCount} sessions',
            [
              {'label': 'Best Score', 'value': '${bestBalanceScore.toInt()}/10'},
              {'label': 'Avg Score', 'value': '${avgBalanceScore.toStringAsFixed(1)}/10'},
              {'label': 'Latest', 'value': '${balanceRecords.first['score'] ?? 0}/10'},
            ],
            Colors.green,
            Icons.balance
          ),
          
        if (balanceCount > 0) SizedBox(height: 8),
          
        // Spike summary (if applicable)
        if (spikeCount > 0) 
          _buildSummaryCard(
            'Spike',
            '${spikeCount} sessions',
            [
              {'label': 'Best Rate', 'value': '${(bestSpikeRate * 100).toStringAsFixed(1)}%'},
              {'label': 'Avg Rate', 'value': '${(avgSpikeRate * 100).toStringAsFixed(1)}%'},
              {'label': 'Latest', 'value': '${(spikeRecords.first['successRate'] ?? 0.0 * 100).toStringAsFixed(1)}%'},
            ],
            Colors.purple,
            Icons.sports_volleyball
          ),
          
        if (spikeCount > 0) SizedBox(height: 8),
          
        // Stamina summary (if applicable)
        if (staminaCount > 0) 
          _buildSummaryCard(
            'Stamina',
            '${staminaCount} sessions',
            [
              {'label': 'Best Time', 'value': bestStaminaTime},
              {'label': 'Latest', 'value': staminaRecords.first['time'] ?? '00:00.0'},
              {'label': 'Total', 'value': '${staminaCount} runs'},
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
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  '$title Training',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: color.withOpacity(0.2)),
            SizedBox(height: 12),
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
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
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
        // Balance chart
        if (balanceRecords.length > 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance Score Progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                height: 200,
                child: _buildLineChart(
                  balanceRecords,
                  (record) => (record['score'] ?? 0).toDouble(),
                  Colors.green,
                  0,
                  10,
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
          
        // Spike chart
        if (spikeRecords.length > 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spike Success Rate',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
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
              SizedBox(height: 24),
            ],
          ),
          
        // Stamina chart
        if (staminaRecords.length > 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stamina Time Progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
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
          horizontalInterval: timeFormat ? 60 : (maxY! > 10 ? 30 : 1),
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
                  return Text('${value.toInt()}');
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
          border: Border.all(color: const Color(0xff37434d), width: 1),
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
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrailingWidget(Map<String, dynamic> record) {
    String recordType = record['recordType'] ?? '';
    
    if (recordType == 'Balance Training') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getScoreColor(record['score']),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${record['score']}/10',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } 
    else if (recordType == 'Spike Training') {
      double successRate = record['successRate'] ?? 0.0;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getSpikeRateColor(successRate),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${(successRate * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    else if (recordType == 'Stamina Training') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          record['time'] ?? '00:00',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getScoreColor(record['score']),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${record['score'] ?? 'N/A'}/10',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Training Record Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildDetailRow('Student', studentName),
              _buildDetailRow('Training Type', record['drillName'] ?? record['recordType'] ?? 'Unknown'),
              _buildDetailRow('Date & Time', formattedDate),
              _buildDetailRow('Week', record['selectedWeek']?.toString() ?? record['weekTimestamp']?.toString() ?? 'N/A'),
              
              // Type-specific details
              if (record['recordType'] == 'Balance Training')
                _buildDetailRow('Score', '${record['score'] ?? 'N/A'}/10'),
              
              // For spike training, show additional details
              if (record['recordType'] == 'Spike Training') ...[
                _buildDetailRow('Success Rate', 
                  '${(record['successRate'] * 100).toStringAsFixed(1)}%'),
                _buildDetailRow('Attempts', 
                  '${record['successfulSpikes'] ?? 0}/${record['totalAttempts'] ?? 0} spikes'),
              ],
              
              // For balance training, show additional details
              if (record['recordType'] == 'Balance Training')
                _buildDetailRow('Attempt', '${record['attempt'] ?? 1}'),
              
              // For stamina training, show time
              if (record['recordType'] == 'Stamina Training')
                _buildDetailRow('Time', record['time'] ?? 'N/A'),
              
              SizedBox(height: 16),
              Text(
                'Coach Notes:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record['notes'] ?? 'No notes provided',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
              
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}