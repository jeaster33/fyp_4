import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'schedule_date_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  final String userId;
  final bool isCoach;

  const ScheduleListScreen({
    Key? key,
    required this.userId,
    this.isCoach = false,
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
              widget.isCoach ? 'Training Sessions' : 'Game Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.isCoach
                  ? _firestore
                      .collection('training_sessions')
                      .where('isCoachSession', isEqualTo: true)
                      .orderBy('date', descending: false)
                      .snapshots()
                  : _firestore
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
                            
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                              child: ListTile(
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
                                  ],
                                ),
                                trailing: widget.isCoach
                                    ? IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () => _confirmDeleteSession(sessionId),
                                      )
                                    : null,
                                onTap: () => _showSessionDetails(session, sessionId),
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
      floatingActionButton: widget.isCoach
          ? FloatingActionButton(
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
            )
          : null,
    );
  }

  void _showSessionDetails(Map<String, dynamic> session, String sessionId) {
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Join the session (for students) or mark attendance (for coaches)
                    if (widget.isCoach) {
                      // Navigate to attendance marking screen
                      // Navigator.of(context).push(...);
                    } else {
                      // Join the session
                      _joinSession(sessionId);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    widget.isCoach ? 'Mark Attendance' : 'Join Session',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _joinSession(String sessionId) async {
    try {
      // Check if user is already in attendees
      DocumentSnapshot sessionDoc = await _firestore
          .collection('training_sessions')
          .doc(sessionId)
          .get();
      
      Map<String, dynamic> sessionData = sessionDoc.data() as Map<String, dynamic>;
      List<dynamic> attendees = sessionData['attendees'] ?? [];
      
      if (!attendees.contains(widget.userId)) {
        // Add user to attendees
        await _firestore.collection('training_sessions').doc(sessionId).update({
          'attendees': FieldValue.arrayUnion([widget.userId]),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined the session')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already registered for this session')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining session: $e')),
      );
    }
  }

  Future<void> _confirmDeleteSession(String sessionId) async {
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
}

