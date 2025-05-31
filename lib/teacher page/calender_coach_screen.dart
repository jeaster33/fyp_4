import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'schedule_date_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  final String userId;

  const ScheduleListScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ScheduleListScreenState createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scheduled Sessions'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'All Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Simple query without filters to avoid index errors
              stream: _firestore
                  .collection('training_sessions')
                  .orderBy('date', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No scheduled sessions found'),
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
                  itemCount: sortedDates.length,
                  itemBuilder: (context, dateIndex) {
                    final date = sortedDates[dateIndex];
                    final sessions = groupedSessions[date]!;
                    final headerDate = DateFormat('EEEE, MMMM d, yyyy')
                        .format(DateTime.parse(date));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            headerDate,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
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
                            
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.all(16.0),
                                    title: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 6),
                                        Text(description),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 16),
                                            SizedBox(width: 4),
                                            Text('$startTime - $endTime'),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        // Attendance status indicator
                                        hasAttendance
                                            ? Row(
                                                children: [
                                                  Icon(Icons.check_circle, 
                                                      color: Colors.green, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Attendance recorded',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                children: [
                                                  Icon(Icons.pending, 
                                                      color: Colors.orange, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Attendance pending',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ],
                                    ),
                                    // Add edit and delete buttons for everyone
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _editSession(session, sessionId),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmDeleteSession(sessionId),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showSessionDetails(session, sessionId),
                                  ),
                                  Divider(height: 1),
                                  // Attendance button row
                                  InkWell(
                                    onTap: () => _takeAttendance(sessionId, session),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      decoration: BoxDecoration(
                                        color: hasAttendance ? Colors.grey[100] : Colors.blue[50],
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            hasAttendance ? Icons.edit : Icons.how_to_reg,
                                            color: hasAttendance ? Colors.grey[700] : Colors.blue,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            hasAttendance ? 'Edit Attendance' : 'Take Attendance',
                                            style: TextStyle(
                                              color: hasAttendance ? Colors.grey[700] : Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
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
      // Everyone gets the add button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ScheduleDateScreen(
                userId: widget.userId,
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session, String sessionId) {
    // Existing code...
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session['title'] ?? 'Untitled Session',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(
                      (session['date'] as Timestamp).toDate(),
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    '${session['startTime']} - ${session['endTime']}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Description:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                session['description'] ?? 'No description provided',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              
              // Attendance status
              if (session.containsKey('attendanceRecorded') && session['attendanceRecorded'] == true)
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.5))
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attendance has been recorded for this session',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 20),
              
              // Take attendance button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    _takeAttendance(sessionId, session);
                  },
                  icon: Icon(session.containsKey('attendanceRecorded') && 
                             session['attendanceRecorded'] == true ? 
                             Icons.edit : Icons.how_to_reg),
                  label: Text(session.containsKey('attendanceRecorded') && 
                              session['attendanceRecorded'] == true ? 
                              'Edit Attendance' : 'Take Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              SizedBox(height: 12),
              
              // Actions row - Edit and Delete buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editSession(session, sessionId),
                      icon: Icon(Icons.edit),
                      label: Text('Edit Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                        _confirmDeleteSession(sessionId);
                      },
                      icon: Icon(Icons.delete),
                      label: Text('Delete Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
      // Return default time if parsing fails
      return TimeOfDay.now();
    }
  }

  void _editSession(Map<String, dynamic> session, String sessionId) {
    // Existing code...
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
    // Existing code...
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Session'),
          content: Text('Are you sure you want to delete this session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteSession(sessionId);
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    // Existing code...
    try {
      await _firestore.collection('training_sessions').doc(sessionId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting session: $e')),
      );
    }
  }

  // New attendance methods
  Future<void> _takeAttendance(String sessionId, Map<String, dynamic> session) async {
    // Get the session date for the title
    final sessionDate = DateFormat('EEEE, MMMM d, yyyy')
        .format((session['date'] as Timestamp).toDate());
    
    // Fetch all students
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Loading students...'),
              ],
            ),
          );
        },
      );

      // Query students (filter by role if needed)
      QuerySnapshot studentSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (studentSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No students found')),
        );
        return;
      }

      // Get previous attendance data if it exists
      Map<String, bool> attendanceData = {};
      DocumentSnapshot sessionDoc = await _firestore
          .collection('training_sessions')
          .doc(sessionId)
          .get();
      
      Map<String, dynamic> sessionData = sessionDoc.data() as Map<String, dynamic>;
      
      if (sessionData.containsKey('attendance') && 
          sessionData['attendance'] is Map) {
        // Convert to the expected format
        Map<String, dynamic> savedAttendance = sessionData['attendance'];
        savedAttendance.forEach((key, value) {
          attendanceData[key] = value as bool;
        });
      }
      
      // Navigate to attendance taking screen
      _showAttendanceDialog(
        context, 
        sessionId, 
        session['title'], 
        sessionDate,
        studentSnapshot.docs,
        attendanceData,
        session, // Pass session map
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Take Attendance'),
                SizedBox(height: 4),
                Text(
                  '$sessionTitle - $sessionDate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FIXED: Responsive button layout
                  Column( // CHANGED: Column instead of Row
                    children: [
                      // All Present button
                      Container(
                        width: double.infinity, // CHANGED: Full width
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              for (var student in students) {
                                attendance[student.id] = true;
                              }
                            });
                          },
                          icon: Icon(Icons.group, size: 18), // CHANGED: Smaller icon
                          label: Text(
                            'Mark All Present',
                            style: TextStyle(fontSize: 14), // CHANGED: Smaller text
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8), // CHANGED: Space between buttons
                      // All Absent button
                      Container(
                        width: double.infinity, // CHANGED: Full width
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              for (var student in students) {
                                attendance[student.id] = false;
                              }
                            });
                          },
                          icon: Icon(Icons.group_off, size: 18), // CHANGED: Smaller icon
                          label: Text(
                            'Mark All Absent',
                            style: TextStyle(fontSize: 14), // CHANGED: Smaller text
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16), // CHANGED: More space
                  Divider(thickness: 1), // CHANGED: Thicker divider
                  SizedBox(height: 16),
                  
                  // Student list with better styling
                  Container(
                    height: 300,
                    decoration: BoxDecoration( // ADDED: Container styling
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
                        
                        return Container( // ADDED: Individual item styling
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.symmetric( // CHANGED: Better padding
                              horizontal: 12,
                              vertical: 4,
                            ),
                            title: Text(
                              studentName,
                              style: TextStyle(
                                fontSize: 14, // CHANGED: Smaller font
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              studentUsername,
                              style: TextStyle(
                                fontSize: 12, // CHANGED: Smaller subtitle
                                color: Colors.grey[600],
                              ),
                            ),
                            value: attendance[studentId] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                attendance[studentId] = value ?? false;
                              });
                            },
                            activeColor: Colors.blue,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.trailing, // ADDED: Checkbox on right
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // CHANGED: Better action button layout
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2, // CHANGED: Make save button larger
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // Update the session with attendance data
                          await _firestore.collection('training_sessions').doc(sessionId).update({
                            'attendance': attendance,
                            'attendanceRecorded': true,
                            'lastAttendanceUpdate': FieldValue.serverTimestamp(),
                          });

                          // Update individual attendance records for each student
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
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error recording attendance: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Save Attendance'),
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
