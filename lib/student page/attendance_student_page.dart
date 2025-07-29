import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceStudentPage extends StatefulWidget {
  const AttendanceStudentPage({super.key});

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
      
      QuerySnapshot recordsSnapshot = await _firestore
          .collection('attendance_records')
          .where('studentId', isEqualTo: userId)
          .get();
          
      print('Retrieved ${recordsSnapshot.docs.length} attendance records');
      
      List<Map<String, dynamic>> records = [];
      int present = 0;
      
      for (var doc in recordsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        DateTime sessionDate;
        try {
          sessionDate = (data['sessionDate'] as Timestamp).toDate();
        } catch (e) {
          sessionDate = DateTime.now();
        }
        
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
      
      records.sort((a, b) => b['sessionDate'].compareTo(a['sessionDate']));
      
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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('My Attendance'),
        backgroundColor: Color(0xFF8B5CF6), // CHANGED: Purple theme matching ATTENDANCE card
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAttendanceRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6), // CHANGED: Purple theme
              ),
            )
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
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
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
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withOpacity(0.15), // CHANGED: Purple theme
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Sessions',
                _totalSessions.toString(),
                Icons.calendar_month,
                Color(0xFF3B82F6),
              ),
              _buildStatItem(
                'Present',
                _presentCount.toString(),
                Icons.check_circle,
                Color(0xFF10B981),
              ),
              _buildStatItem(
                'Absent',
                _absentCount.toString(),
                Icons.cancel,
                Color(0xFFEF4444),
              ),
            ],
          ),
          SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Rate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '${_attendanceRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _getAttendanceColor(_attendanceRate),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey.shade200,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _attendanceRate / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          _getAttendanceColor(_attendanceRate),
                          _getAttendanceColor(_attendanceRate).withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(record['sessionDate']);
    bool isPresent = record['present'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPresent 
              ? Color(0xFF8B5CF6).withOpacity(0.2) // CHANGED: Purple theme for present
              : Color(0xFFEF4444).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isPresent 
                ? Color(0xFF8B5CF6).withOpacity(0.1) // CHANGED: Purple theme for present
                : Color(0xFFEF4444).withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPresent 
                    ? [Color(0xFF8B5CF6), Color(0xFF7C3AED)] // CHANGED: Purple gradient for present
                    : [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPresent ? Icons.check : Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['sessionTitle'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${record['startTime']} - ${record['endTime']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPresent 
                  ? Color(0xFF8B5CF6).withOpacity(0.1) // CHANGED: Purple theme for present
                  : Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: isPresent ? Color(0xFF8B5CF6) : Color(0xFFEF4444), // CHANGED: Purple text for present
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6).withOpacity(0.1), // CHANGED: Purple theme
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              size: 60,
              color: Color(0xFF8B5CF6), // CHANGED: Purple theme
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
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
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Color _getAttendanceColor(double rate) {
    if (rate >= 90) return Color(0xFF8B5CF6); // CHANGED: Use purple for excellent attendance
    if (rate >= 80) return Color(0xFF7C3AED); // CHANGED: Use darker purple for good attendance
    if (rate >= 70) return Color(0xFFF59E0B);
    if (rate >= 60) return Color(0xFFEF4444);
    return Color(0xFFDC2626);
  }
}