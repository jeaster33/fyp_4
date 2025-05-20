import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EnduranceDrillPage.dart';
import 'balance_training.dart';
import 'spike_training.dart';

class StudentListPage extends StatefulWidget {
  final String coachId;
  final String coachName;
  final String drillName;
  final Color drillColor;

  const StudentListPage({
    Key? key,
    required this.coachId,
    required this.coachName,
    required this.drillName,
    required this.drillColor,
  }) : super(key: key);

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Query Firestore for all users with role 'student'
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // Convert to list of maps with the data we need
      List<Map<String, dynamic>> loadedStudents = studentsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'fullName': data['fullName'] ?? 'Unknown',
          'username': data['username'] ?? 'Unknown',
          'profileImageUrl': data['profileImageUrl'] ?? '',
        };
      }).toList();

      // Sort alphabetically by fullName
      loadedStudents.sort((a, b) => a['fullName'].compareTo(b['fullName']));

      setState(() {
        _students = loadedStudents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredStudents() {
    if (_searchQuery.isEmpty) {
      return _students;
    }
    return _students.where((student) {
      return student['fullName'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student['username'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Navigate to appropriate drill page based on drill type
  void _navigateToDrillPage(Map<String, dynamic> student) {
    Widget drillPage;
    
    if (widget.drillName.contains('Stamina')) {
      drillPage = EnduranceDrillPage(
        studentId: student['id'],
        studentName: student['fullName'],
        studentUsername: student['username'],
        studentProfileImage: student['profileImageUrl'],
        coachId: widget.coachId,
        coachName: widget.coachName,
        drillName: widget.drillName,
        drillColor: widget.drillColor,
      );
    } else if (widget.drillName.contains('Balance')) {
      drillPage = BalanceDrillPage(
        studentId: student['id'],
        studentName: student['fullName'],
        studentUsername: student['username'],
        studentProfileImage: student['profileImageUrl'],
        coachId: widget.coachId,
        coachName: widget.coachName,
        drillName: widget.drillName,
        drillColor: widget.drillColor,
      );
    } else if (widget.drillName.contains('Spike')) {
      drillPage = SpikeDrillPage(
        studentId: student['id'],
        studentName: student['fullName'],
        studentUsername: student['username'],
        studentProfileImage: student['profileImageUrl'],
        coachId: widget.coachId,
        coachName: widget.coachName,
        drillName: widget.drillName,
        drillColor: widget.drillColor,
      );
    } else {
      // Default to EnduranceDrillPage if type is unknown
      drillPage = EnduranceDrillPage(
        studentId: student['id'],
        studentName: student['fullName'],
        studentUsername: student['username'],
        studentProfileImage: student['profileImageUrl'],
        coachId: widget.coachId,
        coachName: widget.coachName,
        drillName: widget.drillName,
        drillColor: widget.drillColor,
      );
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => drillPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _getFilteredStudents();

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Student for ${widget.drillName}'),
        backgroundColor: widget.drillColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
                // Student count indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Students: ${filteredStudents.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // Students list
                Expanded(
                  child: filteredStudents.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No students found'
                                : 'No students matching "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () => _navigateToDrillPage(student),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      // Student avatar
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: student['profileImageUrl'].isNotEmpty
                                            ? NetworkImage(student['profileImageUrl'])
                                            : null,
                                        child: student['profileImageUrl'].isEmpty
                                            ? Icon(Icons.person, color: Colors.grey.shade700)
                                            : null,
                                      ),
                                      SizedBox(width: 16),
                                      // Student info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['fullName'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              student['username'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Arrow icon
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: widget.drillColor,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}