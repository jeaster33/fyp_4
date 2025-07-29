import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StaminaPerformancePage extends StatefulWidget {
  const StaminaPerformancePage({super.key});

  @override
  State<StaminaPerformancePage> createState() => _StaminaPerformancePageState();
}

class _StaminaPerformancePageState extends State<StaminaPerformancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _staminaRecords = [];
  
  @override
  void initState() {
    super.initState();
    _loadStaminaRecords();
    print('Stamina Performance page initialized');
  }
  
  Future<void> _loadStaminaRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final String userId = _auth.currentUser!.uid;
      print('Loading stamina data for user ID: $userId');
      
      // Remove orderBy to avoid requiring composite indexes
      QuerySnapshot snapshot = await _firestore
          .collection('stamina_records')
          .where('studentId', isEqualTo: userId)
          .get();
          
      print('Retrieved ${snapshot.docs.length} stamina records from Firestore');
      
      List<Map<String, dynamic>> records = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Parse time string to seconds for graphing
        String timeString = data['time'] ?? '00:00.0';
        int totalSeconds = _parseTimeToSeconds(timeString);
        
        // Convert timestamp to date
        DateTime recordDate;
        try {
          recordDate = (data['timestamp'] as Timestamp).toDate();
        } catch (e) {
          recordDate = DateTime.now();
        }
        
        records.add({
          'id': doc.id,
          'time': timeString,
          'totalSeconds': totalSeconds,
          'timestamp': data['timestamp'],
          'recordDate': recordDate,
          'notes': data['notes'] ?? '',
          'weekTimestamp': data['weekTimestamp'] ?? '',
          'courseName': data['courseName'] ?? 'Unknown Course',
        });
      }
      
      // Sort records client-side by timestamp
      records.sort((a, b) {
        Timestamp aStamp = a['timestamp'] as Timestamp;
        Timestamp bStamp = b['timestamp'] as Timestamp;
        return aStamp.compareTo(bStamp); // Ascending order (oldest first)
      });
      
      print('Processed ${records.length} stamina records');
      
      setState(() {
        _staminaRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stamina records: $e');
      setState(() {
        _isLoading = false;
      });
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
    print('Building stamina performance page with: ${_staminaRecords.length} records');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Stamina Performance'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStaminaRecords,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildStaminaContent(),
    );
  }
  
  Widget _buildStaminaContent() {
    if (_staminaRecords.isEmpty) {
      return _buildEmptyState('No stamina training records found');
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Stamina Performance'),
          _buildStaminaSummary(),
          SizedBox(height: 24),
          _buildStaminaChart(),
          SizedBox(height: 24),
          _buildSectionTitle('Training History'),
          SizedBox(height: 8),
          ..._staminaRecords.reversed.map((record) => _buildStaminaRecordCard(record)),
        ],
      ),
    );
  }
  
  Widget _buildStaminaSummary() {
    String bestTime = '00:00.0';
    String averageTime = '00:00.0';
    String latestTime = '00:00.0';
    
    if (_staminaRecords.isNotEmpty) {
      // Find best time (minimum seconds)
      var bestRecord = _staminaRecords.reduce((a, b) => 
        a['totalSeconds'] < b['totalSeconds'] ? a : b);
      bestTime = bestRecord['time'];
      
      // Calculate average time
      double avgSeconds = _staminaRecords.map((r) => r['totalSeconds'] as int)
        .reduce((a, b) => a + b) / _staminaRecords.length;
      int avgMinutes = (avgSeconds / 60).floor();
      int avgSecs = (avgSeconds % 60).floor();
      averageTime = '$avgMinutes:${avgSecs.toString().padLeft(2, '0')}.0';
      
      // Get latest time
      latestTime = _staminaRecords.last['time'];
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Best Time', bestTime, Icons.emoji_events, Colors.amber),
            _buildStatItem('Average', averageTime, Icons.calculate, Colors.blue),
            _buildStatItem('Latest', latestTime, Icons.update, Colors.green),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStaminaChart() {
    if (_staminaRecords.length < 2) {
      return Center(
        child: Text(
          'Need more training records to display chart',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Progress (Lower is Better)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        int minutes = (value / 60).floor();
                        int seconds = (value % 60).floor();
                        return Text('$minutes:${seconds.toString().padLeft(2, '0')}');
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
                          if (index >= 0 && index < _staminaRecords.length && index % 3 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('W${_staminaRecords[index]['weekTimestamp'].split(' ').last}'),
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
                maxX: _staminaRecords.length.toDouble() - 1,
                minY: 0,
                maxY: _staminaRecords.map((r) => r['totalSeconds'] as int).reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _staminaRecords.length,
                      (i) => FlSpot(i.toDouble(), _staminaRecords[i]['totalSeconds'].toDouble()),
                    ),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStaminaRecordCard(Map<String, dynamic> record) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.timer, color: Colors.blue),
        ),
        title: Text(
          'Time: ${record['time']}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Course: ${record['courseName']}'),
            Text('Week: ${record['weekTimestamp']}'),
            if (record['notes'].isNotEmpty)
              Text(
                'Notes: ${record['notes']}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Text(
          DateFormat('MMM d, yyyy').format(record['recordDate']),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Complete stamina training sessions to see your progress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
}