import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class BalancePerformancePage extends StatefulWidget {
  const BalancePerformancePage({super.key});

  @override
  State<BalancePerformancePage> createState() => _BalancePerformancePageState();
}

class _BalancePerformancePageState extends State<BalancePerformancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _balanceRecords = [];
  
  @override
  void initState() {
    super.initState();
    _loadBalanceRecords();
    print('Balance Performance page initialized');
  }
  
  Future<void> _loadBalanceRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final String userId = _auth.currentUser!.uid;
      print('Loading balance data for user ID: $userId');
      
      QuerySnapshot snapshot = await _firestore
          .collection('balance_records')
          .where('studentId', isEqualTo: userId)
          .get();
          
      print('Retrieved ${snapshot.docs.length} balance records from Firestore');
      
      List<Map<String, dynamic>> records = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Convert timestamp to date
        DateTime recordDate;
        try {
          recordDate = (data['timestamp'] as Timestamp).toDate();
        } catch (e) {
          recordDate = DateTime.now();
        }
        
        // UPDATED: Use jugglingCount as primary field
        int jugglingCount = data['jugglingCount'] ?? data['balanceScore'] ?? 0;
        
        records.add({
          'id': doc.id,
          'jugglingCount': jugglingCount, // CHANGED: Primary field
          'balanceScore': jugglingCount, // CHANGED: For backward compatibility
          'attempt': data['attempt'] ?? 1,
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
      
      print('Processed ${records.length} balance records');
      
      setState(() {
        _balanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading balance records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building balance performance page with: ${_balanceRecords.length} records');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Balance Performance'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBalanceRecords,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBalanceContent(),
    );
  }
  
  Widget _buildBalanceContent() {
    if (_balanceRecords.isEmpty) {
      return _buildEmptyState('No balance training records found');
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Ball Juggling Performance'),
          _buildBalanceSummary(),
          SizedBox(height: 24),
          _buildBalanceChart(),
          SizedBox(height: 24),
          _buildSectionTitle('Training History'),
          SizedBox(height: 8),
          ..._balanceRecords.reversed.map((record) => _buildBalanceRecordCard(record)),
        ],
      ),
    );
  }
  
  Widget _buildBalanceSummary() {
    int bestCount = 0;
    double averageCount = 0;
    int latestCount = 0;
    
    if (_balanceRecords.isNotEmpty) {
      // Find best count (maximum juggles)
      var bestRecord = _balanceRecords.reduce((a, b) => 
        a['jugglingCount'] > b['jugglingCount'] ? a : b);
      bestCount = bestRecord['jugglingCount'];
      
      // Calculate average count
      averageCount = _balanceRecords.map((r) => r['jugglingCount'] as int)
        .reduce((a, b) => a + b) / _balanceRecords.length;
      
      // Get latest count
      latestCount = _balanceRecords.last['jugglingCount'];
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // UPDATED: Changed to show juggling counts instead of "/10" ratings
            _buildStatItem('Best Score', '$bestCount juggles', Icons.emoji_events, Colors.amber),
            _buildStatItem('Average', '${averageCount.toStringAsFixed(1)} juggles', Icons.calculate, Colors.blue),
            _buildStatItem('Latest', '$latestCount juggles', Icons.update, Colors.green),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBalanceChart() {
    if (_balanceRecords.length < 2) {
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
    
    // UPDATED: Calculate dynamic max value based on data
    int maxJuggles = _balanceRecords.map((r) => r['jugglingCount'] as int)
        .reduce((a, b) => a > b ? a : b);
    double chartMaxY = (maxJuggles * 1.2).ceilToDouble(); // 20% padding above max
    if (chartMaxY < 10) chartMaxY = 10; // Minimum scale of 10
    
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
            'Ball Juggling Progress (Number of Successful Juggles)',
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
                      reservedSize: 40, // CHANGED: More space for larger numbers
                      interval: chartMaxY / 5, // CHANGED: Dynamic interval
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}');
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
                          if (index >= 0 && index < _balanceRecords.length && index % 3 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('W${_balanceRecords[index]['weekTimestamp'].split(' ').last}'),
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
                maxX: _balanceRecords.length.toDouble() - 1,
                minY: 0,
                maxY: chartMaxY, // CHANGED: Dynamic max Y
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _balanceRecords.length,
                      (i) => FlSpot(i.toDouble(), _balanceRecords[i]['jugglingCount'].toDouble()),
                    ),
                    isCurved: true,
                    color: Colors.orange, // CHANGED: Orange for balance training
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBalanceRecordCard(Map<String, dynamic> record) {
    int jugglingCount = record['jugglingCount'];
    Color scoreColor = _getJugglingCountColor(jugglingCount); // UPDATED: New color function
    
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor.withOpacity(0.2),
          child: Icon(Icons.sports_handball, color: scoreColor), // CHANGED: Ball icon
        ),
        title: Text(
          'Juggles: $jugglingCount', // UPDATED: Show juggling count
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
  
  // UPDATED: New color function for juggling counts
  Color _getJugglingCountColor(int count) {
    if (count >= 50) return Colors.green;        // Excellent (50+ juggles)
    if (count >= 30) return Colors.lightGreen;   // Very Good (30-49 juggles)
    if (count >= 20) return Colors.orange;       // Good (20-29 juggles)
    if (count >= 10) return Colors.deepOrange;   // Fair (10-19 juggles)
    return Colors.red;                           // Needs Practice (< 10 juggles)
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_handball, // CHANGED: Ball icon
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
            'Complete ball juggling training sessions to see your progress',
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
            fontSize: 16, // CHANGED: Smaller font to fit longer text
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center, // ADDED: Center align
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