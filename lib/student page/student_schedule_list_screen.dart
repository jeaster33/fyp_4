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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Training Schedule'),
        backgroundColor: Color(0xFF3B82F6), // CHANGED: Blue theme matching SCHEDULE card
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header section matching student home screen style
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3B82F6).withOpacity(0.1), // CHANGED: Blue theme
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            margin: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 Upcoming Sessions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your training schedule and session details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
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
                      color: Color(0xFF3B82F6), // CHANGED: Blue theme
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
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

                final sortedDates = groupedSessions.keys.toList()..sort();

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, dateIndex) {
                    final date = sortedDates[dateIndex];
                    final sessions = groupedSessions[date]!;
                    final headerDate = DateFormat('EEEE, MMMM d, yyyy')
                        .format(DateTime.parse(date));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header with blue styling
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)], // CHANGED: Blue gradient
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            headerDate,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
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
                            return _buildSessionCard(session, sessionId);
                          },
                        ),
                        SizedBox(height: 16),
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

  Widget _buildSessionCard(Map<String, dynamic> session, String sessionId) {
    final title = session['title'] ?? 'Untitled Session';
    final description = session['description'] ?? 'No description';
    final startTime = session['startTime'] ?? '';
    final endTime = session['endTime'] ?? '';
    
    final sessionDate = (session['date'] as Timestamp).toDate();
    final isUpcoming = sessionDate.isAfter(DateTime.now().subtract(Duration(days: 1)));
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUpcoming ? Color(0xFF3B82F6).withOpacity(0.3) : Colors.grey.withOpacity(0.2), // CHANGED: Blue theme
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isUpcoming 
                ? Color(0xFF3B82F6).withOpacity(0.15) // CHANGED: Blue theme
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUpcoming 
                        ? [Color(0xFF3B82F6), Color(0xFF1E40AF)] // CHANGED: Blue gradient
                        : [Colors.grey.shade400, Colors.grey.shade500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_handball,
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
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUpcoming)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1), // CHANGED: Blue theme
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Upcoming',
                    style: TextStyle(
                      color: Color(0xFF3B82F6), // CHANGED: Blue theme
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Color(0xFF3B82F6), // CHANGED: Blue theme
              ),
              SizedBox(width: 8),
              Text(
                '$startTime - $endTime',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () => _showSessionDetails(session, sessionId),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1), // CHANGED: Blue theme
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: Color(0xFF3B82F6), // CHANGED: Blue theme
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Color(0xFF3B82F6), // CHANGED: Blue theme
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              color: Color(0xFF3B82F6).withOpacity(0.1), // CHANGED: Blue theme
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              size: 60,
              color: Color(0xFF3B82F6), // CHANGED: Blue theme
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No sessions scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Training sessions will appear here once scheduled',
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

  void _showSessionDetails(Map<String, dynamic> session, String sessionId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                session['title'] ?? 'Untitled Session',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 16),
              _buildDetailRow(
                Icons.calendar_today,
                DateFormat('EEEE, MMMM d, yyyy').format(
                  (session['date'] as Timestamp).toDate(),
                ),
              ),
              SizedBox(height: 12),
              _buildDetailRow(
                Icons.access_time,
                '${session['startTime']} - ${session['endTime']}',
              ),
              SizedBox(height: 20),
              Text(
                'Description:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 8),
              Text(
                session['description'] ?? 'No description provided',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Session added to your calendar'),
                        backgroundColor: Color(0xFF3B82F6), // CHANGED: Blue theme
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.calendar_month, size: 18),
                  label: Text('Add to My Calendar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6), // CHANGED: Blue theme
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF3B82F6).withOpacity(0.1), // CHANGED: Blue theme
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Color(0xFF3B82F6), // CHANGED: Blue theme
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Future<String> _getCreatorName(String userId) async {
    return 'Coach';
  }
}