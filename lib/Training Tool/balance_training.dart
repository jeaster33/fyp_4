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
  }) : super(key: key);

  @override
  _BalanceDrillPageState createState() => _BalanceDrillPageState();
}

class _BalanceDrillPageState extends State<BalanceDrillPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  
  TextEditingController _notesController = TextEditingController();
  int _balanceScore = 7; // Default value on a scale of 1-10
  int _selectedAttempt = 1;
  final List<int> _attempts = [1, 2, 3];
  
  // Week selection variables
  int _selectedWeek = 1;
  final List<int> _weeks = [1, 2, 3, 4];
  
  List<Map<String, dynamic>> _previousRecords = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousRecords();
    _setCurrentWeek();
  }

  void _setCurrentWeek() {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    int daysDifference = now.difference(firstDayOfMonth).inDays;
    int currentWeek = ((daysDifference + firstDayOfMonth.weekday) / 7).ceil();
    
    setState(() {
      _selectedWeek = currentWeek.clamp(1, 4); // Ensure it's between 1-4
    });
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
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> records = [];
      
      for (var doc in recordsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime recordDate = (data['timestamp'] as Timestamp).toDate();
        
        records.add({
          'id': doc.id,
          'attempt': data['attempt'] ?? 1,
          'balanceScore': data['balanceScore'] ?? 5,
          'timestamp': data['timestamp'] as Timestamp,
          'notes': data['notes'] ?? '',
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

  Future<void> _saveRecord() async {
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
        'attempt': _selectedAttempt,
        'balanceScore': _balanceScore,
        'notes': _notesController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'weekTimestamp': weekTimestamp,
        'selectedWeek': _selectedWeek,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record saved successfully for $weekTimestamp')),
      );

      // Reset the form
      _notesController.clear();
      setState(() {
        _balanceScore = 7;
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
                  
                  // Week and Attempt Selection
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
                              Icon(Icons.sports_volleyball, color: widget.drillColor),
                              SizedBox(width: 8),
                              Text(
                                'Balance Drill Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Week selection
                          Column(
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
                          SizedBox(height: 16),
                          // Attempt selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attempt:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedAttempt,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: _attempts.map((int attempt) {
                                  return DropdownMenuItem<int>(
                                    value: attempt,
                                    child: Text('Attempt $attempt'),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedAttempt = newValue!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
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
                  
                  // Balance score slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Balance Score: $_balanceScore/10',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getScoreColor(_balanceScore),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getScoreLabel(_balanceScore),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Slider(
                        value: _balanceScore.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: _getScoreColor(_balanceScore),
                        inactiveColor: Colors.grey.shade300,
                        label: _balanceScore.toString(),
                        onChanged: (double value) {
                          setState(() {
                            _balanceScore = value.round();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Poor',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            'Excellent',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
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
                        'Save Balance Record for ${_getSelectedWeekTimestamp()}',
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
                                                  'Balance Score: ${record['balanceScore']}/10',
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
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getScoreColor(record['balanceScore']),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _getScoreLabel(record['balanceScore']),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Attempt: ${record['attempt']}',
                                              style: TextStyle(
                                                fontSize: 14,
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
  
  Color _getScoreColor(int score) {
    if (score >= 9) return Colors.green;
    if (score >= 7) return Colors.lightGreen;
    if (score >= 5) return Colors.orange;
    if (score >= 3) return Colors.deepOrange;
    return Colors.red;
  }
  
  String _getScoreLabel(int score) {
    if (score >= 9) return 'Excellent';
    if (score >= 7) return 'Good';
    if (score >= 5) return 'Average';
    if (score >= 3) return 'Poor';
    return 'Very Poor';
  }
}