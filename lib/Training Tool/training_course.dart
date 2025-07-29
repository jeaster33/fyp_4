import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TrainingCourseManager extends StatefulWidget {
  final String coachId;
  final String coachName;
  final VoidCallback? onCourseUpdated;

  const TrainingCourseManager({
    super.key,
    required this.coachId,
    required this.coachName,
    this.onCourseUpdated,
  });

  @override
  _TrainingCourseManagerState createState() => _TrainingCourseManagerState();
}

class _TrainingCourseManagerState extends State<TrainingCourseManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isAdmin = false; // ADDED: Track if current user is admin
  Map<String, dynamic>? _activeCourse;
  final TextEditingController _courseNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus(); // ADDED: Check admin status first
    _loadActiveCourse();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  // ADDED: Check if current user is admin
  Future<void> _checkAdminStatus() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _isAdmin = userData['role'] == 'admin';
          });
        }
      }
    } catch (e) {
      print('Error checking admin status: $e');
      setState(() {
        _isAdmin = false;
      });
    }
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

  // UPDATED: Add admin check before starting course
  Future<void> _startNewCourse() async {
    if (!_isAdmin) {
      _showAdminOnlyMessage();
      return;
    }

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
        'createdBy': _auth.currentUser?.uid, // ADDED: Track who created the course
        'createdByRole': 'admin', // ADDED: Track creator role
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New training course started successfully'),
          backgroundColor: Colors.green,
        ),
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
        SnackBar(
          content: Text('Error starting new course'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // UPDATED: Add admin check before ending course
  Future<void> _endCourse() async {
    if (!_isAdmin) {
      _showAdminOnlyMessage();
      return;
    }

    if (_activeCourse == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update course to inactive
      await _firestore.collection('training_courses').doc(_activeCourse!['id']).update({
        'isActive': false,
        'endDate': FieldValue.serverTimestamp(),
        'endedBy': _auth.currentUser?.uid, // ADDED: Track who ended the course
        'endedByRole': 'admin', // ADDED: Track ender role
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Training course ended successfully'),
          backgroundColor: Colors.orange,
        ),
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
        SnackBar(
          content: Text('Error ending course'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ADDED: Show admin-only message
  void _showAdminOnlyMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Admin Access Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Training course management is restricted to administrators only.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please contact your administrator to start or end training courses.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  // UPDATED: Add admin check before showing dialog
  void _showNewCourseDialog() {
    if (!_isAdmin) {
      _showAdminOnlyMessage();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('Start New Training Course'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin privileges detected',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.school),
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

  // UPDATED: Add admin check before showing dialog
  void _showEndCourseDialog() {
    if (!_isAdmin) {
      _showAdminOnlyMessage();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('End Current Training Course'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action requires admin privileges',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to end the current training course?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'You won\'t be able to add more training data to this course once ended.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
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
      // Active course exists - show details and end button (admin only)
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
                        Row(
                          children: [
                            Text(
                              'Active Training Course',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            // ADDED: Admin badge if user is admin
                            if (_isAdmin) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.admin_panel_settings, 
                                         size: 12, color: Colors.blue.shade700),
                                    SizedBox(width: 2),
                                    Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
              // UPDATED: Show different button based on admin status
              _isAdmin
                  ? ElevatedButton.icon(
                      onPressed: _showEndCourseDialog,
                      icon: Icon(Icons.stop_circle),
                      label: Text('End Training Course'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 40),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Colors.grey.shade600, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Course management restricted to admin',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      );
    } else {
      // No active course - show start button (admin only)
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
                        Row(
                          children: [
                            Text(
                              'No Active Course',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            // ADDED: Admin badge if user is admin
                            if (_isAdmin) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.admin_panel_settings, 
                                         size: 12, color: Colors.blue.shade700),
                                    SizedBox(width: 2),
                                    Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _isAdmin 
                              ? 'Start a training course to begin recording training data'
                              : 'Contact admin to start a training course',
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
              // UPDATED: Show different button based on admin status
              _isAdmin
                  ? ElevatedButton.icon(
                      onPressed: _showNewCourseDialog,
                      icon: Icon(Icons.play_circle),
                      label: Text('Start New Training Course'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 40),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Colors.grey.shade600, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Course creation restricted to admin',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      );
    }
  }
}