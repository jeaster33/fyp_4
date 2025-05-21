import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceStudentPage extends StatefulWidget {
  const AttendanceStudentPage({Key? key}) : super(key: key);

  @override
  _AttendanceStudentPageState createState() => _AttendanceStudentPageState();
}

class _AttendanceStudentPageState extends State<AttendanceStudentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendanceRecords = [];
  
  // Statistics
  int _totalSessions = 0;
  int _presentCount = 0;
  int _absentCount = 0;
  double _attendanceRate = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }
  
  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final String userId = _auth.currentUser!.uid;
      
      // Query all attendance records for this student
      QuerySnapshot recordsSnapshot = await _firestore
          .collection('attendance_records')
          .where('studentId', isEqualTo: userId)
          .get();
          
      print('Retrieved ${recordsSnapshot.docs.length} attendance records');
      
      List<Map<String, dynamic>> records = [];
      
      // Process records and calculate statistics
      int present = 0;
      
      for (var doc in recordsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Convert date to DateTime
        DateTime sessionDate;
        try {
          sessionDate = (data['sessionDate'] as Timestamp).toDate();
        } catch (e) {
          sessionDate = DateTime.now();
        }
        
        // Track present/absent counts
        if (data['present'] == true) {
          present++;
        }
        
        records.add({
          'id': doc.id,
          'sessionId': data['sessionId'] ?? '',
          'sessionTitle': data['sessionTitle'] ?? 'Unknown Session',
          'sessionDate': sessionDate,
          'startTime': data['startTime'] ?? '',
          'endTime': data['endTime'] ?? '',
          'present': data['present'] ?? false,
          'recordedAt': data['recordedAt'],
        });
      }
      
      // Sort by date (newest first)
      records.sort((a, b) => b['sessionDate'].compareTo(a['sessionDate']));
      
      // Calculate statistics
      _totalSessions = records.length;
      _presentCount = present;
      _absentCount = _totalSessions - _presentCount;
      _attendanceRate = _totalSessions > 0 ? (_presentCount / _totalSessions) * 100 : 0;
      
      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading attendance records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Attendance'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAttendanceRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_attendanceRecords.isEmpty) {
      return _buildEmptyState();
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCard(),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Attendance History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _attendanceRecords.length,
            itemBuilder: (context, index) {
              return _buildAttendanceCard(_attendanceRecords[index]);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticsCard() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Sessions',
                  _totalSessions.toString(),
                  Icons.calendar_month,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Present',
                  _presentCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Absent',
                  _absentCount.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
            SizedBox(height: 16),
            // Attendance rate progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Rate',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_attendanceRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getAttendanceColor(_attendanceRate),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _attendanceRate / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getAttendanceColor(_attendanceRate),
                  ),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(record['sessionDate']);
    bool isPresent = record['present'];
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isPresent ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: isPresent ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          record['sessionTitle'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(formattedDate),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text('${record['startTime']} - ${record['endTime']}'),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPresent ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
            ),
          ),
          child: Text(
            isPresent ? 'Present' : 'Absent',
            style: TextStyle(
              color: isPresent ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your attendance will appear here once the coach records it',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
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
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
  Color _getAttendanceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 80) return Colors.lightGreen;
    if (rate >= 70) return Colors.amber;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }
}