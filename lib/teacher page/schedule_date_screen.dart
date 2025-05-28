import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../service/notification_service.dart';

class ScheduleDateScreen extends StatefulWidget {
  final String userId;
  final String? existingSessionId; // For editing existing sessions
  final String? existingTitle;
  final String? existingDescription;
  final DateTime? existingDate;
  final TimeOfDay? existingStartTime;
  final TimeOfDay? existingEndTime;

  const ScheduleDateScreen({
    Key? key, 
    required this.userId,
    this.existingSessionId,
    this.existingTitle,
    this.existingDescription,
    this.existingDate,
    this.existingStartTime,
    this.existingEndTime,
  }) : super(key: key);

  @override
  _ScheduleDateScreenState createState() => _ScheduleDateScreenState();
}

class _ScheduleDateScreenState extends State<ScheduleDateScreen> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    
    // Check if we're in edit mode
    _isEditMode = widget.existingSessionId != null;
    
    // Initialize controllers with existing data if in edit mode
    _titleController = TextEditingController(text: widget.existingTitle ?? '');
    _descriptionController = TextEditingController(text: widget.existingDescription ?? '');
    
    // Initialize date and time fields
    selectedDate = widget.existingDate ?? DateTime.now();
    startTime = widget.existingStartTime ?? TimeOfDay.now();
    endTime = widget.existingEndTime ?? 
              TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)), // Allow selecting past dates for editing
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != startTime) {
      setState(() {
        startTime = picked;
        // Automatically adjust end time if it would be before start time
        if (_timeToDouble(endTime) <= _timeToDouble(picked)) {
          endTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
        }
      });
    }
  }

  // Helper to convert TimeOfDay to a comparable double
  double _timeToDouble(TimeOfDay time) {
    return time.hour + time.minute/60.0;
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != endTime) {
      setState(() {
        endTime = picked;
      });
    }
  }

  // New function to send notifications
// Updated _sendNotifications method in schedule_date_screen.dart
Future<void> _sendNotifications(String sessionId, bool isNewSession) async {
  try {
    // Get coach name for the notification
    DocumentSnapshot coachDoc = await _firestore.collection('users').doc(widget.userId).get();
    String coachName = 'Coach';
    if (coachDoc.exists) {
      Map<String, dynamic> coachData = coachDoc.data() as Map<String, dynamic>;
      coachName = coachData['fullName'] ?? 'Coach';
    }

    // Get all students from Firestore
    QuerySnapshot studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    
    // Create a batch for efficient writes
    WriteBatch batch = _firestore.batch();
    
    // Get session details for notification content
    String title = _titleController.text;
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(selectedDate);
    String timeRange = '${startTime.format(context)} - ${endTime.format(context)}';
    
    // Create notification message based on whether it's new or updated
    String studentMessage = isNewSession
        ? "$coachName has scheduled a new training session: $title on $formattedDate at $timeRange"
        : "$coachName has updated a training session: $title on $formattedDate at $timeRange";
    
    String teacherMessage = isNewSession 
        ? "You have scheduled a new training session: $title on $formattedDate at $timeRange" 
        : "You have updated a training session: $title on $formattedDate at $timeRange";

    // First create a notification for the teacher (creator)
    DocumentReference teacherNotificationRef = _firestore.collection('notifications').doc();
    batch.set(teacherNotificationRef, {
      'userId': widget.userId,
      'sessionId': sessionId,
      'title': isNewSession ? 'New Session Created' : 'Session Updated',
      'message': teacherMessage,
      'date': formattedDate,
      'time': timeRange,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'schedule',
    });
    
    // Then create notifications for all students
    for (var studentDoc in studentsSnapshot.docs) {
      String studentId = studentDoc.id;
      
      DocumentReference studentNotificationRef = _firestore.collection('notifications').doc();
      batch.set(studentNotificationRef, {
        'userId': studentId,
        'sessionId': sessionId,
        'title': isNewSession ? 'New Training Session' : 'Training Session Updated',
        'message': studentMessage,
        'date': formattedDate,
        'time': timeRange,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'schedule',
      });
    }
    
    // Commit all notifications in a single batch
    await batch.commit();

    // Send immediate local notification to current user (for testing)
    await NotificationService.sendLocalNotification(
      title: isNewSession ? 'Session Created' : 'Session Updated',
      body: teacherMessage,
    );
    
    print('Notifications sent successfully to teacher and ${studentsSnapshot.docs.length} students');
  } catch (e) {
    print('Error sending notifications: $e');
  }
}

  Future<void> _saveSchedule() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for this session')),
      );
      return;
    }

    // Format times to ensure they're consistently stored
    final formattedStartTime = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final formattedEndTime = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    // Check if end time is after start time using formatted strings for comparison
    if (formattedEndTime.compareTo(formattedStartTime) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String sessionId;
      bool isNewSession = !_isEditMode;
      
      if (_isEditMode) {
        // Update existing session
        sessionId = widget.existingSessionId!;
        await _firestore.collection('training_sessions').doc(sessionId).update({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'date': Timestamp.fromDate(selectedDate),
          'startTime': formattedStartTime,
          'endTime': formattedEndTime,
          'updatedAt': FieldValue.serverTimestamp(),
          // Don't update createdBy, createdAt, or attendees
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session updated successfully')),
        );
      } else {
        // Create new session
        sessionId = _firestore.collection('training_sessions').doc().id;
        
        await _firestore.collection('training_sessions').doc(sessionId).set({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'date': Timestamp.fromDate(selectedDate),
          'startTime': formattedStartTime,
          'endTime': formattedEndTime,
          'createdBy': widget.userId,
          'createdAt': FieldValue.serverTimestamp(),
          'attendees': [widget.userId], // Auto-add creator to attendees
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session scheduled successfully')),
        );

        // Clear form after creating (but not after editing)
        _titleController.clear();
        _descriptionController.clear();
      }
      
      // Send notifications to teacher and students
      await _sendNotifications(sessionId, isNewSession);
      
      // Navigate back after saving
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving session: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(selectedDate);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Session' : 'Create New Session'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditMode ? 'Update Session Details' : 'Create New Schedule',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Session Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: const Text('Select Date'),
                      subtitle: Text(formattedDate),
                      onTap: () => _selectDate(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.blue),
                      title: const Text('Start Time'),
                      subtitle: Text(startTime.format(context)),
                      onTap: () => _selectStartTime(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time_filled, color: Colors.blue),
                      title: const Text('End Time'),
                      subtitle: Text(endTime.format(context)),
                      onTap: () => _selectEndTime(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditMode ? 'Update Session' : 'Schedule Session',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}