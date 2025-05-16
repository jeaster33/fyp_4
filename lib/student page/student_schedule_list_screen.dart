import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentScheduleListScreen extends StatefulWidget {
  final String userId;

  const StudentScheduleListScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _StudentScheduleListScreenState createState() => _StudentScheduleListScreenState();
}

class _StudentScheduleListScreenState extends State<StudentScheduleListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Training Schedule'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Upcoming Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Simple query without filters
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
                            
                            // Check if this session is today or in the future
                            final sessionDate = (session['date'] as Timestamp).toDate();
                            final isUpcoming = sessionDate.isAfter(DateTime.now().subtract(Duration(days: 1)));
                            
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                              // Add a slight color change for upcoming sessions
                              color: isUpcoming ? Colors.blue.shade50 : null,
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
                                // No edit or delete buttons for students
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
              // Show coach/creator information if available
              if (session['createdBy'] != null) ...[
                Text(
                  'Created by:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _getCreatorName(session['createdBy']),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Coach',
                      style: TextStyle(fontSize: 16),
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
              // Add to Calendar button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // This is a placeholder for calendar integration
                    // Here you could add functionality to add to device calendar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Session added to your calendar')),
                    );
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.calendar_month),
                  label: Text('Add to My Calendar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get creator name - in a real app this would fetch from Firestore
  Future<String> _getCreatorName(String userId) async {
    // You could implement a real lookup to get the user's name
    // For now, just return a placeholder
    return 'Coach';
  }
}