import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SpikeDrillPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentUsername;
  final String studentProfileImage;
  final String coachId;
  final String coachName;
  final String drillName;
  final Color drillColor;
  final Map<String, dynamic>? courseData;

  const SpikeDrillPage({
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
  _SpikeDrillPageState createState() => _SpikeDrillPageState();
}

class _SpikeDrillPageState extends State<SpikeDrillPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  
  final TextEditingController _notesController = TextEditingController();
  int _successfulSpikes = 0;
  int _totalAttempts = 10;
  double get _successRate => _totalAttempts > 0 ? _successfulSpikes / _totalAttempts : 0;
  
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

  // CHANGED: Smart percentage formatting function
  String _getFormattedPercentage(double rate) {
    double percentage = rate * 100;
    if (percentage == 100.0) {
      return '100%'; // No decimal for exactly 100%
    } else if (percentage % 1 == 0) {
      return '${percentage.toInt()}%'; // No decimal for whole numbers
    } else {
      return '${percentage.toStringAsFixed(1)}%'; // One decimal for others
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
      // Use a simpler query without ordering to avoid index requirements
      QuerySnapshot recordsSnapshot = await _firestore
          .collection('spike_records')
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
          'successfulSpikes': data['successfulSpikes'] ?? 0,
          'totalAttempts': data['totalAttempts'] ?? 0,
          'successRate': data['totalAttempts'] > 0 ? data['successfulSpikes'] / data['totalAttempts'] : 0,
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

  // Increment/decrement spike counters
  void _incrementSuccessful() {
    if (_successfulSpikes < _totalAttempts) {
      setState(() {
        _successfulSpikes++;
      });
    }
  }

  void _decrementSuccessful() {
    if (_successfulSpikes > 0) {
      setState(() {
        _successfulSpikes--;
      });
    }
  }

  void _incrementTotal() {
    setState(() {
      _totalAttempts++;
    });
  }

  void _decrementTotal() {
    if (_totalAttempts > _successfulSpikes) {
      setState(() {
        _totalAttempts--;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_successfulSpikes > _totalAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successful spikes cannot exceed total attempts')),
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
      await _firestore.collection('spike_records').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'coachId': widget.coachId,
        'coachName': widget.coachName,
        'drillName': widget.drillName,
        'successfulSpikes': _successfulSpikes,
        'totalAttempts': _totalAttempts,
        'successRate': _successRate,
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
      _notesController.clear();
      setState(() {
        _successfulSpikes = 0;
        _totalAttempts = 10;
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
                      
                      // Spike Counter Card
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
                              Text(
                                'Spike Performance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Successful Spikes Counter
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Successful Spikes:',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_circle),
                                    color: Colors.red,
                                    onPressed: _decrementSuccessful,
                                  ),
                                  Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_successfulSpikes',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: widget.drillColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle),
                                    color: Colors.green,
                                    onPressed: _incrementSuccessful,
                                  ),
                                ],
                              ),
                              
                              // Total Attempts Counter
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Total Attempts:',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_circle),
                                    color: Colors.red,
                                    onPressed: _decrementTotal,
                                  ),
                                  Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_totalAttempts',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: widget.drillColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle),
                                    color: Colors.green,
                                    onPressed: _incrementTotal,
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Success Rate - CHANGED: Using smart formatting
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: widget.drillColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Success Rate',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: widget.drillColor,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _getFormattedPercentage(_successRate), // CHANGED: Smart formatting
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: widget.drillColor,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _successRate,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(widget.drillColor),
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
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
                            'Save Spike Record for ${_getSelectedWeekTimestamp()}',
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
                                      'No previous records for this student',
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
                                                      'Success: ${_getFormattedPercentage(record['successRate'])}', // CHANGED: Smart formatting
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
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade100,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '${record['successfulSpikes']} successful',
                                                        style: TextStyle(
                                                          color: Colors.green.shade800,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade100,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '${record['totalAttempts']} attempts',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade800,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value: record['successRate'],
                                              backgroundColor: Colors.grey.shade300,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                _getSuccessRateColor(record['successRate']),
                                              ),
                                              minHeight: 6,
                                              borderRadius: BorderRadius.circular(3),
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
                                            SizedBox(height: 4),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                record['fullDate'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
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
  
  Color _getSuccessRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.lightGreen;
    if (rate >= 0.4) return Colors.orange;
    if (rate >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }
}