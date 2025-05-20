import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TrainingCourseManager extends StatefulWidget {
  final String coachId;
  final String coachName;
  final VoidCallback? onCourseUpdated;

  const TrainingCourseManager({
    Key? key,
    required this.coachId,
    required this.coachName,
    this.onCourseUpdated,
  }) : super(key: key);

  @override
  _TrainingCourseManagerState createState() => _TrainingCourseManagerState();
}

class _TrainingCourseManagerState extends State<TrainingCourseManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _activeCourse;
  final TextEditingController _courseNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActiveCourse();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveCourse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot courseSnapshot = await _firestore
          .collection('training_courses')
          .where('coachId', isEqualTo: widget.coachId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (courseSnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = courseSnapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        DateTime startDate = (data['startDate'] as Timestamp).toDate();
        DateTime currentDate = DateTime.now();
        int daysSinceStart = currentDate.difference(startDate).inDays;
        int currentWeek = (daysSinceStart / 7).floor() + 1;
        
        setState(() {
          _activeCourse = {
            'id': doc.id,
            'courseName': data['courseName'],
            'startDate': startDate,
            'currentWeek': currentWeek,
            ...data,
          };
        });
      } else {
        setState(() {
          _activeCourse = null;
        });
      }
    } catch (e) {
      print('Error loading active course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading course information')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startNewCourse() async {
    if (_courseNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a course name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add new course document
      DocumentReference courseRef = await _firestore.collection('training_courses').add({
        'courseName': _courseNameController.text,
        'coachId': widget.coachId,
        'coachName': widget.coachName,
        'startDate': FieldValue.serverTimestamp(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New training course started successfully')),
      );

      // Reload the active course data
      await _loadActiveCourse();
      
      // Notify parent if callback exists
      if (widget.onCourseUpdated != null) {
        widget.onCourseUpdated!();
      }
      
      // Clear text field
      _courseNameController.clear();
      
      // Close the dialog if shown
      Navigator.of(context).pop();
      
    } catch (e) {
      print('Error starting course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting new course')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _endCourse() async {
    if (_activeCourse == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update course to inactive
      await _firestore.collection('training_courses').doc(_activeCourse!['id']).update({
        'isActive': false,
        'endDate': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Training course ended successfully')),
      );

      // Reload the active course data
      await _loadActiveCourse();
      
      // Notify parent if callback exists
      if (widget.onCourseUpdated != null) {
        widget.onCourseUpdated!();
      }
      
    } catch (e) {
      print('Error ending course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending course')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showNewCourseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start New Training Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Starting a new course will begin at Week 1. You can track progress through weeks as training continues.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _courseNameController,
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g., "Spring 2025 Sepak Takraw"',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _startNewCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Start Course'),
            ),
          ],
        );
      },
    );
  }

  void _showEndCourseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('End Current Training Course'),
          content: Text(
            'Are you sure you want to end the current training course? You won\'t be able to add more training data to this course once ended.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _endCourse();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('End Course'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_activeCourse != null) {
      // Active course exists - show details and end button
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.school, color: Colors.green),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Training Course',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          _activeCourse!['courseName'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'Week ${_activeCourse!['currentWeek']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                                    Text(
                    'Started: ${DateFormat('MMM d, yyyy').format(_activeCourse!['startDate'] is Timestamp 
                        ? (_activeCourse!['startDate'] as Timestamp).toDate() 
                        : _activeCourse!['startDate'])}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showEndCourseDialog,
                icon: Icon(Icons.stop_circle),
                label: Text('End Training Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // No active course - show start button
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.school, color: Colors.orange),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Active Course',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'Start a training course to begin recording training data',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showNewCourseDialog,
                icon: Icon(Icons.play_circle),
                label: Text('Start New Training Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}