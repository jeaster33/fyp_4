import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class GenerateReportPage extends StatefulWidget {
  final String coachId;
  final String coachName;

  const GenerateReportPage({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  _GenerateReportPageState createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String? _selectedStudentId;
  Map<String, String> _studentNames = {};
  Map<String, dynamic> _studentInfo = {};
  List<Map<String, dynamic>> _studentRecords = [];

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
      // Get all students
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      Map<String, String> studentNames = {};
      
      for (var doc in studentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        studentNames[doc.id] = data['fullName'] ?? 'Unknown';
      }
      
      // Sort students alphabetically by name
      final sortedEntries = studentNames.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      Map<String, String> sortedStudentNames = Map.fromEntries(sortedEntries);
      
      setState(() {
        _studentNames = sortedStudentNames;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
  }

  Future<void> _loadStudentData(String studentId) async {
    setState(() {
      _isLoading = true;
      _studentRecords = [];
      _studentInfo = {};
    });

    try {
      // Get student profile info
      DocumentSnapshot studentDoc = await _firestore
          .collection('users')
          .doc(studentId)
          .get();
      
      if (studentDoc.exists) {
        Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
        setState(() {
          _studentInfo = studentData;
        });
      }
      
      // Load balance records - UPDATED to use juggling count
      List<Map<String, dynamic>> allRecords = [];
      
      QuerySnapshot balanceSnapshot = await _firestore
          .collection('balance_records')
          .where('studentId', isEqualTo: studentId)
          .get();
          
      for (var doc in balanceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // CHANGED: Use juggling count instead of balance score
        int jugglingCount = data['jugglingCount'] ?? data['balanceScore'] ?? 0;
        
        allRecords.add({
          'id': doc.id,
          'recordType': 'Balance Training',
          'jugglingCount': jugglingCount, // ADDED: Store juggling count
          'score': jugglingCount, // Keep for compatibility with other logic
          'timestamp': data['timestamp'],
          'courseName': data['courseName'] ?? 'Unknown Course',
          'notes': data['notes'] ?? '',
          'weekTimestamp': data['weekTimestamp'] ?? '',
          'drillName': data['drillName'] ?? 'Balance Training',
        });
      }
      
      // Load spike records
      QuerySnapshot spikeSnapshot = await _firestore
          .collection('spike_records')
          .where('studentId', isEqualTo: studentId)
          .get();
          
      for (var doc in spikeSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        double successRate = data['successRate'] ?? 0.0;
        
        allRecords.add({
          'id': doc.id,
          'recordType': 'Spike Training',
          'successRate': successRate,
          'timestamp': data['timestamp'],
          'courseName': data['courseName'] ?? 'Unknown Course',
          'notes': data['notes'] ?? '',
          'weekTimestamp': data['weekTimestamp'] ?? '',
          'drillName': data['drillName'] ?? 'Spike Training',
        });
      }
      
      // Load stamina records
      QuerySnapshot staminaSnapshot = await _firestore
          .collection('stamina_records')
          .where('studentId', isEqualTo: studentId)
          .get();
          
      for (var doc in staminaSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        allRecords.add({
          'id': doc.id,
          'recordType': 'Stamina Training',
          'time': data['time'] ?? '00:00.0',
          'timestamp': data['timestamp'],
          'courseName': data['courseName'] ?? 'Unknown Course',
          'notes': data['notes'] ?? '',
          'weekTimestamp': data['weekTimestamp'] ?? '',
          'drillName': data['drillName'] ?? 'Stamina Training',
        });
      }

      // Get attendance records for calculating attendance percentage
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance_records')
          .where('studentId', isEqualTo: studentId)
          .get();
      
      int totalSessions = attendanceSnapshot.docs.length;
      int presentCount = 0;
      
      for (var doc in attendanceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['present'] == true) {
          presentCount++;
        }
      }
      
      // Calculate attendance percentage
      double attendancePercentage = totalSessions > 0 
          ? (presentCount / totalSessions) * 100 
          : 0.0;
      
      // Add attendance data to student info
      setState(() {
        _studentInfo['attendancePercentage'] = attendancePercentage;
        _studentInfo['totalSessions'] = totalSessions;
        _studentInfo['presentCount'] = presentCount;
      });
      
      // Sort all records by date (newest first)
      allRecords.sort((a, b) {
        Timestamp aTimestamp = a['timestamp'] as Timestamp;
        Timestamp bTimestamp = b['timestamp'] as Timestamp;
        return bTimestamp.compareTo(aTimestamp);
      });
      
      setState(() {
        _studentRecords = allRecords;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading student data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading student data: $e')),
      );
    }
  }

  Future<void> _generateAndDownloadPDF() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Prepare training data summaries
      Map<String, dynamic> trainingData = _prepareTrainingData();
      
      // Generate the PDF
      final pdf = pw.Document();
      
      // Header without logo
      
      final studentName = _studentNames[_selectedStudentId] ?? 'Unknown Student';
      final reportDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
      
      // First Page - Cover and Summary
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Sepak Takraw Training Report',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Generated on: $reportDate',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),
                
                // Student Info
                pw.Text(
                  'Player Performance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                pw.Text(
                  'Player Information',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfInfoRow('Name', studentName),
                      _buildPdfInfoRow('ID', _selectedStudentId ?? ''),
                      _buildPdfInfoRow('Email', _studentInfo['email'] ?? 'Not available'),
                      _buildPdfInfoRow('Phone', _studentInfo['phoneNumber'] ?? 'Not available'),
                      _buildPdfInfoRow('IC Number', _studentInfo['icNumber'] ?? 'Not available'),
                      _buildPdfInfoRow('Date of Birth', _studentInfo['dateOfBirth'] != null 
                          ? DateFormat('MMMM d, yyyy').format((_studentInfo['dateOfBirth'] as Timestamp).toDate())
                          : 'Not available'),
                      _buildPdfInfoRow('Coach', widget.coachName),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Attendance Summary
                pw.Text(
                  'Attendance Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfInfoRow('Total Sessions', '${_studentInfo['totalSessions'] ?? 0}'),
                      _buildPdfInfoRow('Present', '${_studentInfo['presentCount'] ?? 0}'),
                      _buildPdfInfoRow('Attendance Rate', 
                          '${(_studentInfo['attendancePercentage'] ?? 0.0).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                pw.Divider(),
                
                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by Sepak Takraw Training App',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Page 1',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      // Second Page - Performance Analysis & Training Sessions Summary
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header (update the page title)
                pw.Text(
                  'Performance Analysis - $studentName',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 20),

                // Keep the existing Performance Analysis section
                pw.Text(
                  'Performance Analysis',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(_generateAnalysisText(trainingData)),
                ),

                pw.SizedBox(height: 30),

                // Training Sessions Summary
                pw.Text(
                  'Training Sessions Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Training sessions summary container
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Total training sessions
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 15,
                            height: 15,
                            margin: pw.EdgeInsets.only(right: 8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red500,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Text(
                            'Total Training Sessions: ${trainingData['balanceCount'] + trainingData['spikeCount'] + trainingData['staminaCount']}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      
                      // Training sessions by type
                      pw.Text(
                        'Sessions by Training Type:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      
                      // Balance training
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 12,
                            height: 12,
                            margin: pw.EdgeInsets.only(right: 8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green500,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Text(
                            'Balance Training: ${trainingData['balanceCount']} sessions',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      
                      // Spike training
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 12,
                            height: 12,
                            margin: pw.EdgeInsets.only(right: 8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue500,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Text(
                            'Spike Training: ${trainingData['spikeCount']} sessions',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      
                      // Stamina training
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 12,
                            height: 12,
                            margin: pw.EdgeInsets.only(right: 8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.orange500,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Text(
                            'Stamina Training: ${trainingData['staminaCount']} sessions',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),
                pw.Divider(),

                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by Sepak Takraw Training App',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Page 2',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      // Training Records Pages (Paginate with 20 records per page)
      if (_studentRecords.isNotEmpty) {
        // Constants for pagination
        final int recordsPerPage = 20;
        final int totalRecords = _studentRecords.length;
        final int totalPages = (totalRecords / recordsPerPage).ceil();
        
        for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
          // Calculate record range for this page
          final int startIdx = pageIndex * recordsPerPage;
          final int endIdx = (startIdx + recordsPerPage < totalRecords) 
            ? startIdx + recordsPerPage 
            : totalRecords;
          
          // Get records for this page
          final pageRecords = _studentRecords.sublist(startIdx, endIdx);
          
          // Page number for footer (now starting at 3)
          final int pageNumber = pageIndex + 3;
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header
                    pw.Text(
                      'Training Records - $studentName',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Page ${pageIndex + 1} of $totalPages',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    pw.SizedBox(height: 20),
                    
                    // Table header
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400),
                      columnWidths: {
                        0: pw.FlexColumnWidth(3),
                        1: pw.FlexColumnWidth(3),
                        2: pw.FlexColumnWidth(2),
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Date',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Training Type',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Performance',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        
                        // Record rows for this page
                        ...pageRecords.map((record) {
                          final timestamp = record['timestamp'] as Timestamp?;
                          final dateTime = timestamp?.toDate() ?? DateTime.now();
                          final formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
                          
                          String performance = '';
                          if (record['recordType'] == 'Balance Training') {
                            // CHANGED: Show juggling count instead of score/10
                            int jugglingCount = record['jugglingCount'] ?? record['score'] ?? 0;
                            performance = '$jugglingCount juggles';
                          } else if (record['recordType'] == 'Spike Training') {
                            double successRate = record['successRate'] ?? 0.0;
                            performance = '${(successRate * 100).toStringAsFixed(1)}%';
                          } else if (record['recordType'] == 'Stamina Training') {
                            performance = record['time'] ?? 'N/A';
                          } else {
                            performance = '${record['score'] ?? 'N/A'}/10';
                          }
                          
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: pw.EdgeInsets.all(5),
                                child: pw.Text(formattedDate),
                              ),
                              pw.Padding(
                                padding: pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  record['drillName'] ?? record['recordType'] ?? 'Unknown',
                                ),
                              ),
                              pw.Padding(
                                padding: pw.EdgeInsets.all(5),
                                child: pw.Text(performance),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    
                    pw.Spacer(),
                    pw.Divider(),
                    
                    // Footer
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Generated by Sepak Takraw Training App',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'Page $pageNumber',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        }
      }
      
      // Save the PDF to a file
      final output = await getTemporaryDirectory();
      final String studentNameForFile = studentName.replaceAll(' ', '_');
      final String fileName = '${studentNameForFile}_performance_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      setState(() {
        _isLoading = false;
      });
      
      // Open the PDF file
      OpenFile.open(file.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved: $fileName')),
      );
      
    } catch (e) {
      print('Error generating PDF: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF report: ${e.toString().substring(0, min(50, e.toString().length))}')),
      );
    }
  }

  Map<String, dynamic> _prepareTrainingData() {
    // Count different training types
    int balanceCount = 0;
    int spikeCount = 0;
    int staminaCount = 0;
    
    // Performance metrics - UPDATED for juggling count
    int bestJugglingCount = 0; // CHANGED: From double to int
    double avgJugglingCount = 0; // CHANGED: Represents average juggling count
    double bestSpikeRate = 0;
    double avgSpikeRate = 0;
    String bestStaminaTime = '00:00.0';
    double balanceTrend = 0; // CHANGED: Now represents juggling count trend
    double spikeTrend = 0;
    double staminaTrend = 0;
    
    for (var record in _studentRecords) {
      String recordType = record['recordType'];
      
      if (recordType == 'Balance Training') {
        balanceCount++;
        // CHANGED: Use juggling count instead of score
        int jugglingCount = record['jugglingCount'] ?? record['score'] ?? 0;
        avgJugglingCount += jugglingCount;
        if (jugglingCount > bestJugglingCount) bestJugglingCount = jugglingCount;
      } 
      else if (recordType == 'Spike Training') {
        spikeCount++;
        double rate = record['successRate'] ?? 0.0;
        avgSpikeRate += rate;
        if (rate > bestSpikeRate) bestSpikeRate = rate;
      } 
      else if (recordType == 'Stamina Training') {
        staminaCount++;
        String time = record['time'] ?? '00:00.0';
        
        // Compare times to find best (lowest) time
        if (bestStaminaTime == '00:00.0' || _compareStaminaTimes(time, bestStaminaTime) < 0) {
          bestStaminaTime = time;
        }
      }
    }
    
    // Calculate averages
    if (balanceCount > 0) avgJugglingCount /= balanceCount; // CHANGED: Now calculates average juggling count
    if (spikeCount > 0) avgSpikeRate /= spikeCount;
    
    // Calculate performance trends (if at least 2 records)
    if (balanceCount >= 2) {
      balanceTrend = _calculatePerformanceTrend(
        _studentRecords.where((r) => r['recordType'] == 'Balance Training').toList(),
        (r) => (r['jugglingCount'] ?? r['score'] ?? 0).toDouble(), // CHANGED: Use juggling count
      );
    }
    
    if (spikeCount >= 2) {
      spikeTrend = _calculatePerformanceTrend(
        _studentRecords.where((r) => r['recordType'] == 'Spike Training').toList(),
        (r) => (r['successRate'] ?? 0).toDouble(),
      );
    }
    
    if (staminaCount >= 2) {
      // For stamina, lower is better, so we invert the trend
      staminaTrend = -_calculateStaminaTrend(
        _studentRecords.where((r) => r['recordType'] == 'Stamina Training').toList(),
        (r) => r['time'] as String,
      );
    }
    
    // Calculate best stamina time in seconds for further processing
    int bestStaminaSeconds = _parseTimeToSeconds(bestStaminaTime);
    
    return {
      'balanceCount': balanceCount,
      'spikeCount': spikeCount,
      'staminaCount': staminaCount,
      'bestJugglingCount': bestJugglingCount, // CHANGED: From bestBalanceScore
      'avgJugglingCount': avgJugglingCount, // CHANGED: From avgBalanceScore
      'bestSpikeRate': bestSpikeRate,
      'avgSpikeRate': avgSpikeRate,
      'bestStaminaTime': bestStaminaTime,
      'bestStaminaSeconds': bestStaminaSeconds,
      'balanceTrend': balanceTrend,
      'spikeTrend': spikeTrend,
      'staminaTrend': staminaTrend,
    };
  }

  double _calculatePerformanceTrend(List<Map<String, dynamic>> records, double Function(Map<String, dynamic>) getValue) {
    if (records.length < 2) return 0;
    
    // Sort by date (oldest first)
    records.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp;
      final bTimestamp = b['timestamp'] as Timestamp;
      return aTimestamp.compareTo(bTimestamp);
    });
    
    // Calculate average of first 3 (or fewer) vs last 3 (or fewer)
    int firstCount = min(3, records.length ~/ 2);
    int lastCount = min(3, records.length - firstCount);
    
    if (firstCount == 0 || lastCount == 0) return 0;
    
    double firstAvg = 0;
    for (int i = 0; i < firstCount; i++) {
      firstAvg += getValue(records[i]);
    }
    firstAvg /= firstCount;
    
    double lastAvg = 0;
    for (int i = records.length - lastCount; i < records.length; i++) {
      lastAvg += getValue(records[i]);
    }
    lastAvg /= lastCount;
    
    return lastAvg - firstAvg;
  }

  double _calculateStaminaTrend(List<Map<String, dynamic>> records, String Function(Map<String, dynamic>) getTimeString) {
    if (records.length < 2) return 0;
    
    // Sort by date (oldest first)
    records.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp;
      final bTimestamp = b['timestamp'] as Timestamp;
      return aTimestamp.compareTo(bTimestamp);
    });
    
    // Calculate average of first 3 (or fewer) vs last 3 (or fewer)
    int firstCount = min(3, records.length ~/ 2);
    int lastCount = min(3, records.length - firstCount);
    
    if (firstCount == 0 || lastCount == 0) return 0;
    
    // Convert time strings to seconds
    List<int> firstSeconds = [];
    for (int i = 0; i < firstCount; i++) {
      firstSeconds.add(_parseTimeToSeconds(getTimeString(records[i])));
    }
    
    List<int> lastSeconds = [];
    for (int i = records.length - lastCount; i < records.length; i++) {
      lastSeconds.add(_parseTimeToSeconds(getTimeString(records[i])));
    }
    
    // Calculate averages
    double firstAvg = firstSeconds.reduce((a, b) => a + b) / firstCount;
    double lastAvg = lastSeconds.reduce((a, b) => a + b) / lastCount;
    
    // For stamina, improvement is when time decreases
    if (firstAvg == 0) return 0; // Avoid division by zero
    
    return (firstAvg - lastAvg) / firstAvg; // Return as percentage change
  }

  int _parseTimeToSeconds(String timeString) {
    try {
      List<String> parts = timeString.split(':');
      if (parts.length != 2) return 0;
      
      int minutes = int.parse(parts[0]);
      double seconds = double.parse(parts[1]);
      return (minutes * 60) + seconds.toInt();
    } catch (e) {
      return 0;
    }
  }

  int _compareStaminaTimes(String time1, String time2) {
    // Convert times to seconds and compare
    int seconds1 = _parseTimeToSeconds(time1);
    int seconds2 = _parseTimeToSeconds(time2);
    return seconds1 - seconds2; // negative if time1 is better (lower)
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateAnalysisText(Map<String, dynamic> data) {
    List<String> analysis = [];
    
    // Overall summary
    int totalTrainings = data['balanceCount'] + data['spikeCount'] + data['staminaCount'];
    analysis.add('Overall Summary:');
    analysis.add('- Completed $totalTrainings training sessions');
    
    // Balance analysis - UPDATED for juggling count
    if (data['balanceCount'] > 0) {
      analysis.add('\nBalance Training (Ball Juggling):'); // CHANGED title
      analysis.add('- Completed ${data['balanceCount']} balance training sessions');
      analysis.add('- Best juggling count: ${data['bestJugglingCount']} juggles'); // CHANGED
      analysis.add('- Average juggling count: ${(data['avgJugglingCount'] as double).toStringAsFixed(1)} juggles'); // CHANGED
      
      if (data['balanceTrend'] > 0) {
        analysis.add('- Juggling performance is improving (+${(data['balanceTrend'] as double).toStringAsFixed(1)} juggles)'); // CHANGED
      } else if (data['balanceTrend'] < 0) {
        analysis.add('- Juggling performance has declined (${(data['balanceTrend'] as double).toStringAsFixed(1)} juggles)'); // CHANGED
      } else {
        analysis.add('- Juggling performance has remained consistent'); // CHANGED
      }
    }
    
    // Spike analysis
    if (data['spikeCount'] > 0) {
      analysis.add('\nSpike Training:');
      analysis.add('- Completed ${data['spikeCount']} spike training sessions');
      analysis.add('- Best success rate: ${((data['bestSpikeRate'] as double) * 100).toStringAsFixed(1)}%');
      analysis.add('- Average success rate: ${((data['avgSpikeRate'] as double) * 100).toStringAsFixed(1)}%');
      
      if (data['spikeTrend'] > 0) {
        analysis.add('- Spike performance is improving (+${((data['spikeTrend'] as double) * 100).toStringAsFixed(1)}%)');
      } else if (data['spikeTrend'] < 0) {
        analysis.add('- Spike performance has declined (${((data['spikeTrend'] as double) * 100).toStringAsFixed(1)}%)');
      } else {
        analysis.add('- Spike performance has remained consistent');
      }
    }
    
    // Stamina analysis
    if (data['staminaCount'] > 0) {
      analysis.add('\nStamina Training:');
      analysis.add('- Completed ${data['staminaCount']} stamina training sessions');
      analysis.add('- Best time: ${data['bestStaminaTime']}');
      
      if (data['staminaTrend'] > 0) {
        analysis.add('- Stamina performance is improving (${(data['staminaTrend'] * 100).toStringAsFixed(1)}% faster)');
      } else if (data['staminaTrend'] < 0) {
        analysis.add('- Stamina performance has declined (${(-data['staminaTrend'] * 100).toStringAsFixed(1)}% slower)');
      } else {
        analysis.add('- Stamina performance has remained consistent');
      }
    }
    
    // If no training data
    if (totalTrainings == 0) {
      analysis = ['No training data available for analysis.'];
    }
    
    return analysis.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Performance Report'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Player Performance Report',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Generate a comprehensive performance report for a student',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Student selector
                  Text(
                    'Select Student',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text('Select a student'),
                        value: _selectedStudentId,
                        items: _studentNames.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStudentId = value;
                            });
                            _loadStudentData(value);
                          }
                        },
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Show student data and report preview if a student is selected
                  if (_selectedStudentId != null && !_isLoading) ...[
                    // Training data summary - UPDATED to show juggling count
                    Text(
                      'Training Data Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Records: ${_studentRecords.length}'),
                          Text(
                            'Balance Training (Juggling): ${_studentRecords.where((r) => r['recordType'] == 'Balance Training').length} sessions', // CHANGED
                          ),
                          Text(
                            'Spike Training: ${_studentRecords.where((r) => r['recordType'] == 'Spike Training').length} sessions',
                          ),
                          Text(
                            'Stamina Training: ${_studentRecords.where((r) => r['recordType'] == 'Stamina Training').length} sessions',
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _generateAndDownloadPDF,
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text('Generate PDF Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  if (_selectedStudentId == null && !_isLoading) ...[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Select a student to generate a report',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}