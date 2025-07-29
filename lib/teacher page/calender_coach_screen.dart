import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'schedule_date_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  final String userId;

  const ScheduleListScreen({
    super.key,
    required this.userId,
  });

  @override
  _ScheduleListScreenState createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC), // MATCHING: Same background as schedule date screen
      appBar: AppBar(
        title: Text(
          'Scheduled Sessions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // MATCHING: Bold white text
        ),
        backgroundColor: Color(0xFF3B82F6), // MATCHING: Same blue color
        foregroundColor: Colors.white,
        elevation: 0, // MATCHING: No elevation
        shape: RoundedRectangleBorder( // MATCHING: Rounded bottom corners
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          // MATCHING: Header section with better styling
          Container(
            padding: EdgeInsets.all(20), // MATCHING: Same padding as schedule date screen
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.event_note, color: Color(0xFF3B82F6), size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'All Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937), // MATCHING: Same text color
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('training_sessions')
                  .orderBy('date', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6), // MATCHING: Same blue color
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Error loading sessions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, color: Colors.grey, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'No scheduled sessions found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to create your first session',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group sessions by date
                Map<String, List<DocumentSnapshot>> groupedSessions = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['date'] as Timestamp;
                  final date = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
                  
                  if (!groupedSessions.containsKey(date)) {
                    groupedSessions[date] = [];
                  }
                  groupedSessions[date]!.add(doc);
                }

                // Sort dates
                final sortedDates = groupedSessions.keys.toList()..sort();

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16), // MATCHING: Same padding pattern
                  itemCount: sortedDates.length,
                  itemBuilder: (context, dateIndex) {
                    final date = sortedDates[dateIndex];
                    final sessions = groupedSessions[date]!;
                    final headerDate = DateFormat('EEEE, MMMM d, yyyy')
                        .format(DateTime.parse(date));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // MATCHING: Date header with same styling as schedule screen cards
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: EdgeInsets.only(bottom: 12, top: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient( // MATCHING: Gradient like save button
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.white, size: 18),
                              SizedBox(width: 12),
                              Text(
                                headerDate,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: sessions.length,
                          itemBuilder: (context, sessionIndex) {
                            final session = sessions[sessionIndex].data() as Map<String, dynamic>;
                            final sessionId = sessions[sessionIndex].id;
                            final title = session['title'] ?? 'Untitled Session';
                            final description = session['description'] ?? 'No description';
                            final startTime = session['startTime'] ?? '';
                            final endTime = session['endTime'] ?? '';
                            
                            // Check if attendance has been taken for this session
                            bool hasAttendance = session.containsKey('attendanceRecorded') && 
                                               session['attendanceRecorded'] == true;
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 16), // MATCHING: Consistent spacing
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16), // MATCHING: Same border radius
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05), // MATCHING: Same shadow
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(20), // MATCHING: Same padding as input fields
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF3B82F6).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.event, color: Color(0xFF3B82F6), size: 16),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF1F2937), // MATCHING: Same text color
                                                ),
                                              ),
                                            ),
                                            // Action buttons
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit, color: Color(0xFF3B82F6), size: 18),
                                                    onPressed: () => _editSession(session, sessionId),
                                                    padding: EdgeInsets.all(8),
                                                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.delete, color: Colors.red, size: 18),
                                                    onPressed: () => _confirmDeleteSession(sessionId),
                                                    padding: EdgeInsets.all(8),
                                                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        
                                        // Time and attendance status
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF10B981).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(Icons.access_time, color: Color(0xFF10B981), size: 14),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '$startTime - $endTime',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            Spacer(),
                                            // Attendance status
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: hasAttendance ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    hasAttendance ? Icons.check_circle : Icons.pending,
                                                    color: hasAttendance ? Colors.green : Colors.orange,
                                                    size: 14,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    hasAttendance ? 'Recorded' : 'Pending',
                                                    style: TextStyle(
                                                      color: hasAttendance ? Colors.green : Colors.orange,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // MATCHING: Attendance button with similar styling to save button
                                  Container(
                                    width: double.infinity,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: hasAttendance ? Colors.grey.shade100 : Color(0xFF3B82F6).withOpacity(0.1),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _takeAttendance(sessionId, session),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              hasAttendance ? Icons.edit : Icons.how_to_reg,
                                              color: hasAttendance ? Colors.grey.shade700 : Color(0xFF3B82F6),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              hasAttendance ? 'Edit Attendance' : 'Take Attendance',
                                              style: TextStyle(
                                                color: hasAttendance ? Colors.grey.shade700 : Color(0xFF3B82F6),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // MATCHING: Floating action button with same styling
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // MATCHING: Same gradient as save button
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ScheduleDateScreen(
                  userId: widget.userId,
                ),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }


  // Existing helper methods
  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]), 
        minute: int.parse(parts[1])
      );
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  void _editSession(Map<String, dynamic> session, String sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleDateScreen(
          userId: widget.userId,
          existingSessionId: sessionId,
          existingTitle: session['title'],
          existingDescription: session['description'],
          existingDate: (session['date'] as Timestamp).toDate(),
          existingStartTime: _parseTimeOfDay(session['startTime'] ?? '00:00'),
          existingEndTime: _parseTimeOfDay(session['endTime'] ?? '00:00'),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSession(String sessionId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // MATCHING: Rounded corners
          title: Text('Delete Session'),
          content: Text('Are you sure you want to delete this session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteSession(sessionId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await _firestore.collection('training_sessions').doc(sessionId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session deleted successfully'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting session: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // New attendance methods
  Future<void> _takeAttendance(String sessionId, Map<String, dynamic> session) async {
    final sessionDate = DateFormat('EEEE, MMMM d, yyyy')
        .format((session['date'] as Timestamp).toDate());
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                CircularProgressIndicator(color: Color(0xFF3B82F6)),
                SizedBox(width: 20),
                Text('Loading students...'),
              ],
            ),
          );
        },
      );

      QuerySnapshot studentSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      Navigator.of(context).pop();
      
      if (studentSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No students found'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      Map<String, bool> attendanceData = {};
      DocumentSnapshot sessionDoc = await _firestore
          .collection('training_sessions')
          .doc(sessionId)
          .get();
      
      Map<String, dynamic> sessionData = sessionDoc.data() as Map<String, dynamic>;
      
      if (sessionData.containsKey('attendance') && 
          sessionData['attendance'] is Map) {
        Map<String, dynamic> savedAttendance = sessionData['attendance'];
        savedAttendance.forEach((key, value) {
          attendanceData[key] = value as bool;
        });
      }
      
      _showAttendanceDialog(
        context, 
        sessionId, 
        session['title'], 
        sessionDate,
        studentSnapshot.docs,
        attendanceData,
        session,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showAttendanceDialog(
    BuildContext context,
    String sessionId,
    String sessionTitle,
    String sessionDate,
    List<QueryDocumentSnapshot> students,
    Map<String, bool> existingAttendance,
    Map<String, dynamic> session,
  ) async {
    Map<String, bool> attendance = Map.from(existingAttendance);
    
    for (var student in students) {
      String studentId = student.id;
      if (!attendance.containsKey(studentId)) {
        attendance[studentId] = false;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // MATCHING: Rounded corners
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.how_to_reg, color: Color(0xFF3B82F6), size: 16),
                      ),
                      SizedBox(width: 8),
                      Text('Take Attendance', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$sessionTitle - $sessionDate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                for (var student in students) {
                                  attendance[student.id] = true;
                                }
                              });
                            },
                            icon: Icon(Icons.group, size: 16),
                            label: Text('Mark All Present', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                for (var student in students) {
                                  attendance[student.id] = false;
                                }
                              });
                            },
                            icon: Icon(Icons.group_off, size: 16),
                            label: Text('Mark All Absent', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    Divider(thickness: 1),
                    SizedBox(height: 16),
                    
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          var student = students[index].data() as Map<String, dynamic>;
                          String studentId = students[index].id;
                          String studentName = student['fullName'] ?? 'Unknown Student';
                          String studentUsername = student['username'] ?? '';
                          
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              title: Text(
                                studentName,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                studentUsername,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              value: attendance[studentId] ?? false,
                              onChanged: (bool? value) {
                                setState(() {
                                  attendance[studentId] = value ?? false;
                                });
                              },
                              activeColor: Color(0xFF3B82F6), // MATCHING: Same blue color
                              checkColor: Colors.white,
                              controlAffinity: ListTileControlAffinity.trailing,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _firestore.collection('training_sessions').doc(sessionId).update({
                                'attendance': attendance,
                                'attendanceRecorded': true,
                                'lastAttendanceUpdate': FieldValue.serverTimestamp(),
                              });

                              for (var student in students) {
                                String studentId = student.id;
                                bool isPresent = attendance[studentId] ?? false;
                                
                                String attendanceRecordId = '$sessionId-$studentId';
                                
                                await _firestore.collection('attendance_records').doc(attendanceRecordId).set({
                                  'sessionId': sessionId,
                                  'sessionTitle': sessionTitle,
                                  'sessionDate': session['date'],
                                  'startTime': session['startTime'],
                                  'endTime': session['endTime'],
                                  'studentId': studentId,
                                  'present': isPresent,
                                  'recordedBy': widget.userId,
                                  'recordedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                              }
                              
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Attendance recorded successfully'),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            } catch (e) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error recording attendance: $e'),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3B82F6), // MATCHING: Same blue color
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Save', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}