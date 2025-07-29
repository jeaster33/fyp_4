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
    super.key, 
    required this.userId,
    this.existingSessionId,
    this.existingTitle,
    this.existingDescription,
    this.existingDate,
    this.existingStartTime,
    this.existingEndTime,
  });

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
            primaryColor: Color(0xFF3B82F6),
            colorScheme: ColorScheme.light(primary: Color(0xFF3B82F6)),
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
            primaryColor: Color(0xFF3B82F6),
            colorScheme: ColorScheme.light(primary: Color(0xFF3B82F6)),
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
            primaryColor: Color(0xFF3B82F6),
            colorScheme: ColorScheme.light(primary: Color(0xFF3B82F6)),
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
        SnackBar(
          content: Text('Please enter a title for this session'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Format times to ensure they're consistently stored
    final formattedStartTime = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final formattedEndTime = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    // Check if end time is after start time using formatted strings for comparison
    if (formattedEndTime.compareTo(formattedStartTime) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
          SnackBar(
            content: Text('Session updated successfully'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
          SnackBar(
            content: Text('Session scheduled successfully'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
        SnackBar(
          content: Text('Error saving session: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Session' : 'Create New Session',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REMOVED: Header section completely removed
            
            // Text fields section - no change
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Session Title',
                  labelStyle: TextStyle(color: Color(0xFF3B82F6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(12),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.title, color: Color(0xFF3B82F6), size: 20),
                  ),
                ),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Color(0xFF3B82F6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                  alignLabelWithHint: true,
                  prefixIcon: Container(
                    margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description, color: Color(0xFF3B82F6), size: 20),
                  ),
                ),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            
            // Date & Time card - no change
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.schedule, color: Color(0xFF3B82F6), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Date & Time',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_today, color: Color(0xFF3B82F6), size: 20),
                        ),
                        title: Text('Select Date', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(formattedDate, style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w500)),
                        onTap: () => _selectDate(context),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.access_time, color: Color(0xFF10B981), size: 20),
                        ),
                        title: Text('Start Time', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(startTime.format(context), style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w500)),
                        onTap: () => _selectStartTime(context),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.access_time_filled, color: Color(0xFFEF4444), size: 20),
                        ),
                        title: Text('End Time', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(endTime.format(context), style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w500)),
                        onTap: () => _selectEndTime(context),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Save button - no change
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
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
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isEditMode ? Icons.update : Icons.check_circle, size: 22),
                          SizedBox(width: 10),
                          Text(
                            _isEditMode ? 'Update Session' : 'Schedule Session',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}