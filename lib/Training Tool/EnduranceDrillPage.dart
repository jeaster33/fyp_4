import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class EnduranceDrillPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentUsername;
  final String studentProfileImage;
  final String coachId;
  final String coachName;
  final String drillName;
  final Color drillColor;
  final Map<String, dynamic>? courseData;

  const EnduranceDrillPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
    required this.studentProfileImage,
    required this.coachId,
    required this.coachName,
    required this.drillName,
    required this.drillColor,
    this.courseData,
  });

  @override
  _EnduranceDrillPageState createState() => _EnduranceDrillPageState();
}

class _EnduranceDrillPageState extends State<EnduranceDrillPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _timerRunning = false;
  bool _timerPaused = false;
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsedTime = '00:00.0';
  
  final TextEditingController _notesController = TextEditingController();
  
  // Week selection variables
  int _selectedWeek = 1;
  
  List<Map<String, dynamic>> _previousRecords = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousRecords();
    // Use course week if available
    if (widget.courseData != null) {
      setState(() {
        _selectedWeek = widget.courseData!['currentWeek'];
      });
    }
  }

  String _getSelectedWeekTimestamp() {
    return 'Week $_selectedWeek';
  }

  Future<void> _loadPreviousRecords() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      // Simple query without ordering to avoid index requirements
      QuerySnapshot recordsSnapshot = await _firestore
          .collection('stamina_records')
          .where('studentId', isEqualTo: widget.studentId)
          .get();

      List<Map<String, dynamic>> records = [];
      
      for (var doc in recordsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Check if this record belongs to the current course (client-side filtering)
        if (widget.courseData != null && 
            data['courseId'] != widget.courseData!['id']) {
          continue; // Skip records not from this course
        }
        
        // Convert Timestamp to DateTime safely
        DateTime recordDate;
        try {
          recordDate = (data['timestamp'] as Timestamp).toDate();
        } catch (e) {
          recordDate = DateTime.now(); // Fallback
        }
        
        records.add({
          'id': doc.id,
          'time': data['time'] ?? '00:00.0',
          'timestamp': data['timestamp'],
          'notes': data['notes'] ?? '',
          'weekTimestamp': data['weekTimestamp'] ?? 'Not specified',
          'fullDate': DateFormat('MMM d, yyyy - h:mm a').format(recordDate),
        });
      }

      // Sort the records client-side instead of using orderBy
      records.sort((a, b) {
        Timestamp aStamp = a['timestamp'] as Timestamp;
        Timestamp bStamp = b['timestamp'] as Timestamp;
        return bStamp.compareTo(aStamp); // Descending order (newest first)
      });

      // Limit to 10 records
      if (records.length > 10) {
        records = records.sublist(0, 10);
      }

      setState(() {
        _previousRecords = records;
        _loadingHistory = false;
      });
    } catch (e) {
      print('Error loading previous records: $e');
      setState(() {
        _loadingHistory = false;
      });
    }
  }

  void _startTimer() {
    _stopwatch.start();
    _timerRunning = true;
    _timerPaused = false;
    
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _updateDisplay();
        });
      }
    });
  }

  void _pauseTimer() {
    _stopwatch.stop();
    _timer.cancel();
    _timerRunning = true;
    _timerPaused = true;
  }

  void _resumeTimer() {
    _stopwatch.start();
    _timerPaused = false;
    
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _updateDisplay();
        });
      }
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer.cancel();
    _timerRunning = false;
    _timerPaused = false;
    _updateDisplay();
  }

  void _resetTimer() {
    _stopwatch.reset();
    setState(() {
      _elapsedTime = '00:00.0';
      _timerRunning = false;
      _timerPaused = false;
    });
  }

  void _updateDisplay() {
    final milliseconds = _stopwatch.elapsedMilliseconds;
    final minutes = (milliseconds / 60000).floor().toString().padLeft(2, '0');
    final seconds = ((milliseconds % 60000) / 1000).floor().toString().padLeft(2, '0');
    final tenths = ((milliseconds % 1000) / 100).floor();
    
    _elapsedTime = '$minutes:$seconds.$tenths';
  }

  Future<void> _saveRecord() async {
    if (_elapsedTime == '00:00.0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please record a time before saving')),
      );
      return;
    }

    if (widget.courseData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No active training course')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String weekTimestamp = _getSelectedWeekTimestamp();
      
      // Save the record to Firestore with course data
      await _firestore.collection('stamina_records').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'coachId': widget.coachId,
        'coachName': widget.coachName,
        'drillName': widget.drillName,
        'time': _elapsedTime,
        'notes': _notesController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'weekTimestamp': weekTimestamp,
        'selectedWeek': _selectedWeek,
        'courseId': widget.courseData!['id'],
        'courseName': widget.courseData!['courseName'],
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record saved successfully for $weekTimestamp')),
      );

      // Reset the form
      _resetTimer();
      _notesController.clear();

      // Reload previous records
      _loadPreviousRecords();
    } catch (e) {
      print('Error saving record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving record')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_timerRunning && !_timerPaused) {
      _timer.cancel();
    }
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record ${widget.drillName}'),
        backgroundColor: widget.drillColor,
        foregroundColor: Colors.white,
      ),
      body: widget.courseData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Active Training Course',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please start a training course to record training data',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.drillColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            )
          : _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student info card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Student avatar
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: widget.studentProfileImage.isNotEmpty
                                        ? NetworkImage(widget.studentProfileImage)
                                        : null,
                                    child: widget.studentProfileImage.isEmpty
                                        ? Icon(Icons.person, size: 30, color: Colors.grey.shade700)
                                        : null,
                                  ),
                                  SizedBox(width: 16),
                                  // Student details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.studentName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          widget.studentUsername,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Drill: ${widget.drillName}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: widget.drillColor,
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
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Course and Week Information Card
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.school, color: widget.drillColor),
                                  SizedBox(width: 8),
                                  Text(
                                    'Training Course',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.courseData!['courseName'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                                  SizedBox(width: 4),
                                  Text(
                                    'Started: ${DateFormat('MMM d, yyyy').format(
                                      widget.courseData!['startDate'] is Timestamp 
                                        ? (widget.courseData!['startDate'] as Timestamp).toDate() 
                                        : widget.courseData!['startDate']
                                    )}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: widget.drillColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: widget.drillColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.access_time, color: widget.drillColor),
                                    SizedBox(width: 8),
                                    Text(
                                      'Recording for: Week $_selectedWeek',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: widget.drillColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Timer display
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 48),
                              decoration: BoxDecoration(
                                color: widget.drillColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: widget.drillColor.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                _elapsedTime,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: widget.drillColor,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // Timer control buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!_timerRunning)
                                  ElevatedButton.icon(
                                    onPressed: _startTimer,
                                    icon: Icon(Icons.play_arrow),
                                    label: Text('Start'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                if (_timerRunning && !_timerPaused)
                                  ElevatedButton.icon(
                                    onPressed: _pauseTimer,
                                    icon: Icon(Icons.pause),
                                    label: Text('Pause'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                if (_timerRunning && _timerPaused)
                                  ElevatedButton.icon(
                                    onPressed: _resumeTimer,
                                    icon: Icon(Icons.play_arrow),
                                    label: Text('Resume'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                SizedBox(width: 12),
                                if (_timerRunning)
                                  ElevatedButton.icon(
                                    onPressed: _stopTimer,
                                    icon: Icon(Icons.stop),
                                    label: Text('Stop'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                if (!_timerRunning && _elapsedTime != '00:00.0')
                                  ElevatedButton.icon(
                                    onPressed: _resetTimer,
                                    icon: Icon(Icons.refresh),
                                    label: Text('Reset'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Notes field
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Coach Notes',
                          hintText: 'Add observations, feedback or areas for improvement',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveRecord,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.drillColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Save Record for ${_getSelectedWeekTimestamp()}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Previous records section
                      Text(
                        'Training History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      _loadingHistory
                          ? Center(child: CircularProgressIndicator())
                          : _previousRecords.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'No previous records for this drill',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _previousRecords.length,
                                  itemBuilder: (context, index) {
                                    final record = _previousRecords[index];
                                    
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      record['time'],
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: widget.drillColor,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.calendar_today,
                                                          size: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          record['weekTimestamp'],
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: widget.drillColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  record['fullDate'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (record['notes'].isNotEmpty) SizedBox(height: 8),
                                            if (record['notes'].isNotEmpty)
                                              Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                ),
                                                child: Text(
                                                  record['notes'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
    );
  }
}