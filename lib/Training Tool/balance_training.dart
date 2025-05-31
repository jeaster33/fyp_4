import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BalanceDrillPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentUsername;
  final String studentProfileImage;
  final String coachId;
  final String coachName;
  final String drillName;
  final Color drillColor;
  final Map<String, dynamic>? courseData;

  const BalanceDrillPage({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
    required this.studentProfileImage,
    required this.coachId,
    required this.coachName,
    required this.drillName,
    required this.drillColor,
    this.courseData,
  }) : super(key: key);

  @override
  _BalanceDrillPageState createState() => _BalanceDrillPageState();
}

class _BalanceDrillPageState extends State<BalanceDrillPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  
  TextEditingController _notesController = TextEditingController();
  int _jugglingCount = 0; // Number of successful ball juggles
  
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
      QuerySnapshot recordsSnapshot = await _firestore
          .collection('balance_records')
          .where('studentId', isEqualTo: widget.studentId)
          .get();

      List<Map<String, dynamic>> records = [];
      
      for (var doc in recordsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Check if this record belongs to the current course
        if (widget.courseData != null && 
            data['courseId'] != widget.courseData!['id']) {
          continue;
        }
        
        DateTime recordDate;
        try {
          recordDate = (data['timestamp'] as Timestamp).toDate();
        } catch (e) {
          recordDate = DateTime.now();
        }
        
        records.add({
          'id': doc.id,
          'jugglingCount': data['jugglingCount'] ?? 0,
          'timestamp': data['timestamp'],
          'notes': data['notes'] ?? '',
          'weekTimestamp': data['weekTimestamp'] ?? 'Not specified',
          'fullDate': DateFormat('MMM d, yyyy - h:mm a').format(recordDate),
        });
      }

      // Sort records by timestamp (newest first)
      records.sort((a, b) {
        Timestamp aStamp = a['timestamp'] as Timestamp;
        Timestamp bStamp = b['timestamp'] as Timestamp;
        return bStamp.compareTo(aStamp);
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

  Future<void> _saveRecord() async {
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
      
      // Save the record to Firestore
      await _firestore.collection('balance_records').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'coachId': widget.coachId,
        'coachName': widget.coachName,
        'drillName': widget.drillName,
        'jugglingCount': _jugglingCount, // Store the actual juggling count
        'balanceScore': _jugglingCount, // For compatibility, use same value
        'notes': _notesController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'weekTimestamp': weekTimestamp,
        'selectedWeek': _selectedWeek,
        'courseId': widget.courseData!['id'],
        'courseName': widget.courseData!['courseName'],
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record saved: $_jugglingCount juggles for $weekTimestamp'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset the form
      _notesController.clear();
      setState(() {
        _jugglingCount = 0;
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
                                          'Drill: Ball Juggling Training',
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
                                      'Recording for: Week ${_selectedWeek}',
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
                      
                      SizedBox(height: 32),
                      
                      // Ball Juggling Counter Section
                      Text(
                        'Juggling Count',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // UPDATED: Juggling count input with smaller, cleaner counter
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // UPDATED: Cleaner counter display without icon
                              Container(
                                padding: EdgeInsets.all(20), // Reduced padding
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.drillColor.withOpacity(0.8),
                                      widget.drillColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16), // Smaller radius
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.drillColor.withOpacity(0.3),
                                      blurRadius: 8, // Reduced blur
                                      offset: Offset(0, 4), // Smaller offset
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // REMOVED: Ball icon for cleaner look
                                    Text(
                                      'Ball Juggles',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '$_jugglingCount',
                                      style: TextStyle(
                                        fontSize: 42, // Slightly smaller
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 20), // Reduced spacing
                              
                              // Counter controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Decrease button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: IconButton(
                                      onPressed: _jugglingCount > 0 ? () {
                                        setState(() {
                                          _jugglingCount--;
                                        });
                                      } : null,
                                      icon: Icon(
                                        Icons.remove,
                                        color: _jugglingCount > 0 ? Colors.red : Colors.grey,
                                        size: 28,
                                      ),
                                      iconSize: 48,
                                    ),
                                  ),
                                  
                                  // Manual input
                                  Container(
                                    width: 120,
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter count',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onChanged: (value) {
                                        int? count = int.tryParse(value);
                                        if (count != null && count >= 0) {
                                          setState(() {
                                            _jugglingCount = count;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  
                                  // Increase button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _jugglingCount++;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.add,
                                        color: Colors.green,
                                        size: 28,
                                      ),
                                      iconSize: 48,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Quick preset buttons
                              Text(
                                'Quick Presets:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [5, 10, 15, 20, 25, 30, 40, 50].map((count) {
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _jugglingCount = count;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _jugglingCount == count 
                                            ? widget.drillColor.withOpacity(0.2)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _jugglingCount == count 
                                              ? widget.drillColor
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          color: _jugglingCount == count 
                                              ? widget.drillColor
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Notes field
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Coach Notes',
                          hintText: 'Add observations about technique, consistency, or areas for improvement',
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
                            'Save Record: $_jugglingCount juggles for ${_getSelectedWeekTimestamp()}',
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
                                    int juggles = record['jugglingCount'] ?? 0;
                                    
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
                                                    // UPDATED: Removed ball icon from history records too
                                                    Text(
                                                      '$juggles Juggles',
                                                      style: TextStyle(
                                                        fontSize: 18,
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
}