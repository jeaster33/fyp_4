import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SpikePerformancePage extends StatefulWidget {
  const SpikePerformancePage({Key? key}) : super(key: key);

  @override
  State<SpikePerformancePage> createState() => _SpikePerformancePageState();
}

class _SpikePerformancePageState extends State<SpikePerformancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _spikeRecords = [];
  
  @override
  void initState() {
    super.initState();
    _loadSpikeRecords();
    print('Spike Performance page initialized');
  }
  
  Future<void> _loadSpikeRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final String userId = _auth.currentUser!.uid;
      print('Loading spike data for user ID: $userId');
      
      // Remove orderBy to avoid requiring composite indexes
      QuerySnapshot snapshot = await _firestore
          .collection('spike_records')
          .where('studentId', isEqualTo: userId)
          .get();
          
      print('Retrieved ${snapshot.docs.length} spike records from Firestore');
      
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
        
        records.add({
          'id': doc.id,
          'successfulSpikes': data['successfulSpikes'] ?? 0,
          'totalAttempts': data['totalAttempts'] ?? 0,
          'successRate': data['successRate'] ?? 0.0,
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
      
      print('Processed ${records.length} spike records');
      
      setState(() {
        _spikeRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading spike records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    print('Building spike performance page with: ${_spikeRecords.length} records');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Spike Performance'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSpikeRecords,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildSpikeContent(),
    );
  }
  
  Widget _buildSpikeContent() {
    if (_spikeRecords.isEmpty) {
      return _buildEmptyState('No spike training records found');
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Spike Performance'),
          _buildSpikeSummary(),
          SizedBox(height: 24),
          _buildSpikeChart(),
          SizedBox(height: 24),
          _buildSectionTitle('Training History'),
          SizedBox(height: 8),
          ..._spikeRecords.reversed.map((record) => _buildSpikeRecordCard(record)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildSpikeSummary() {
    double bestRate = 0.0;
    double averageRate = 0.0;
    double latestRate = 0.0;
    
    if (_spikeRecords.isNotEmpty) {
      // Find best success rate
      var bestRecord = _spikeRecords.reduce((a, b) => 
        a['successRate'] > b['successRate'] ? a : b);
      bestRate = bestRecord['successRate'];
      
      // Calculate average rate
      averageRate = _spikeRecords.map((r) => r['successRate'] as double)
        .reduce((a, b) => a + b) / _spikeRecords.length;
      
      // Get latest rate
      latestRate = _spikeRecords.last['successRate'];
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Best Rate', '${(bestRate * 100).toStringAsFixed(1)}%', Icons.emoji_events, Colors.amber),
            _buildStatItem('Average', '${(averageRate * 100).toStringAsFixed(1)}%', Icons.calculate, Colors.blue),
            _buildStatItem('Latest', '${(latestRate * 100).toStringAsFixed(1)}%', Icons.update, Colors.green),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpikeChart() {
    if (_spikeRecords.length < 2) {
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
            'Spike Success Rate (Higher is Better)',
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
                      interval: 0.2,
                      getTitlesWidget: (value, meta) {
                        return Text('${(value * 100).toInt()}%');
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
                          if (index >= 0 && index < _spikeRecords.length && index % 3 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('W${_spikeRecords[index]['weekTimestamp'].split(' ').last}'),
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
                maxX: _spikeRecords.length.toDouble() - 1,
                minY: 0,
                maxY: 1.0,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _spikeRecords.length,
                      (i) => FlSpot(i.toDouble(), _spikeRecords[i]['successRate'].toDouble()),
                    ),
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.purple.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpikeRecordCard(Map<String, dynamic> record) {
    double successRate = record['successRate'];
    Color rateColor = _getSpikeRateColor(successRate);
    
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rateColor.withOpacity(0.2),
          child: Icon(Icons.sports_volleyball, color: rateColor),
        ),
        title: Text(
          'Success Rate: ${(successRate * 100).toStringAsFixed(1)}%',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Course: ${record['courseName']}'),
            Text('Week: ${record['weekTimestamp']}'),
            Text('${record['successfulSpikes']} / ${record['totalAttempts']} successful spikes'),
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
  
  Color _getSpikeRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.lightGreen;
    if (rate >= 0.4) return Colors.orange;
    if (rate >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_volleyball,
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
            'Complete spike training sessions to see your progress',
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