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

  const EnduranceDrillPage({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
    required this.studentProfileImage,
    required this.coachId,
    required this.coachName,
    required this.drillName,
    required this.drillColor,
  }) : super(key: key);

  @override
  _EnduranceDrillPageState createState() => _EnduranceDrillPageState();
}

class _EnduranceDrillPageState extends State<EnduranceDrillPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _timerRunning = false;
  bool _timerPaused = false;
  Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsedTime = '00:00.0';
  
  TextEditingController _notesController = TextEditingController();
  int _intensityRating = 3;
  
  // Week selection variables
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int _selectedWeek = 1;
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<int> _weeks = [1, 2, 3, 4];
  
  List<Map<String, dynamic>> _previousRecords = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousRecords();
    // Set initial week based on current date
    _setCurrentWeek();
  }

  void _setCurrentWeek() {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    int daysDifference = now.difference(firstDayOfMonth).inDays;
    int currentWeek = ((daysDifference + firstDayOfMonth.weekday) / 7).ceil();
    
    setState(() {
      _selectedMonth = DateFormat('MMMM').format(now);
      _selectedWeek = currentWeek.clamp(1, 4); // Ensure it's between 1-4
    });
  }

  String _getSelectedWeekTimestamp() {
    return '$_selectedMonth Week $_selectedWeek';
  }

  Future<void> _loadPreviousRecords() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      QuerySnapshot recordsSnapshot = await _firestore
          .collection('stamina_records')
          .where('studentId', isEqualTo: widget.studentId)
          .where('drillName', isEqualTo: widget.drillName)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> records = [];
      
      for (var doc in recordsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime recordDate = (data['timestamp'] as Timestamp).toDate();
        
        records.add({
          'id': doc.id,
          'time': data['time'] ?? '00:00.0',
          'timestamp': data['timestamp'] as Timestamp,
          'notes': data['notes'] ?? '',
          'intensityRating': data['intensityRating'] ?? 3,
          'weekTimestamp': data['weekTimestamp'] ?? 'Not specified',
          'fullDate': DateFormat('MMM d, yyyy - h:mm a').format(recordDate),
        });
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

    setState(() {
      _isLoading = true;
    });

    try {
      String weekTimestamp = _getSelectedWeekTimestamp();
      
      // Save the record to Firestore
      await _firestore.collection('stamina_records').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'coachId': widget.coachId,
        'coachName': widget.coachName,
        'drillName': widget.drillName,
        'time': _elapsedTime,
        'notes': _notesController.text,
        'intensityRating': _intensityRating,
        'timestamp': FieldValue.serverTimestamp(),
        'weekTimestamp': weekTimestamp,
        'selectedMonth': _selectedMonth,
        'selectedWeek': _selectedWeek,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record saved successfully for $weekTimestamp')),
      );

      // Reset the form
      _resetTimer();
      _notesController.clear();
      setState(() {
        _intensityRating = 3;
      });

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
      body: _isLoading
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
                  
                  // Week Selection Card
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
                              Icon(Icons.calendar_today, color: widget.drillColor),
                              SizedBox(width: 8),
                              Text(
                                'Select Recording Week',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              // Month selection
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Month:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedMonth,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: _months.map((String month) {
                                        return DropdownMenuItem<String>(
                                          value: month,
                                          child: Text(month),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedMonth = newValue!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              // Week selection
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Week:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    DropdownButtonFormField<int>(
                                      value: _selectedWeek,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: _weeks.map((int week) {
                                        return DropdownMenuItem<int>(
                                          value: week,
                                          child: Text('Week $week'),
                                        );
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        setState(() {
                                          _selectedWeek = newValue!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          // Selected week display
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: widget.drillColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.drillColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Recording for: ${_getSelectedWeekTimestamp()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: widget.drillColor,
                              ),
                              textAlign: TextAlign.center,
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
                  
                  // Performance details section
                  Text(
                    'Performance Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Intensity rating
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Intensity Rating:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Low', style: TextStyle(color: Colors.grey.shade600)),
                          Row(
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _intensityRating = index + 1;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Icon(
                                    Icons.fitness_center,
                                    size: 28,
                                    color: index < _intensityRating
                                        ? widget.drillColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }),
                          ),
                          Text('High', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
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
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'Intensity: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Row(
                                              children: List.generate(5, (i) {
                                                return Icon(
                                                  Icons.fitness_center,
                                                  size: 14,
                                                  color: i < record['intensityRating']
                                                      ? widget.drillColor
                                                      : Colors.grey.shade300,
                                                );
                                              }),
                                            ),
                                          ],
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