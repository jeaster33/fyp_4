/*import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class GenerateReportPage extends StatefulWidget {
  final String coachId;
  final String coachName;

  const GenerateReportPage({
    Key? key,
    required this.coachId,
    required this.coachName,
  }) : super(key: key);

  @override
  _GenerateReportPageState createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, String> _studentNames = {};
  String? _selectedStudentId;
  List<Map<String, dynamic>> _studentRecords = [];
  
  // For charts rendering as images
  final GlobalKey _balanceChartKey = GlobalKey();
  final GlobalKey _spikeChartKey = GlobalKey();
  final GlobalKey _staminaChartKey = GlobalKey();
  
  // Additional student info
  Map<String, dynamic> _studentInfo = {};
  TextEditingController _notesController = TextEditingController();
  
  // Helper function to get min of two integers
  int min(int a, int b) {
    return a < b ? a : b;
  }
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all students related to this coach
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      // Check which students have training records with this coach
      Map<String, String> studentNames = {};
      
      for (var doc in studentsSnapshot.docs) {
        String studentId = doc.id;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Verify if this student has training records with this coach
        bool hasRecords = await _hasTrainingRecords(studentId);
        
        if (hasRecords) {
          String fullName = data['fullName'] ?? 'Unknown Student';
          studentNames[studentId] = fullName;
        }
      }
      
      setState(() {
        _studentNames = studentNames;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading students')),
      );
    }
  }
  
  Future<bool> _hasTrainingRecords(String studentId) async {
    try {
      // Check if student has any training records with this coach
      QuerySnapshot balanceSnapshot = await _firestore
          .collection('balance_records')
          .where('coachId', isEqualTo: widget.coachId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
          
      if (balanceSnapshot.docs.isNotEmpty) return true;
      
      QuerySnapshot spikeSnapshot = await _firestore
          .collection('spike_records')
          .where('coachId', isEqualTo: widget.coachId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
          
      if (spikeSnapshot.docs.isNotEmpty) return true;
      
      QuerySnapshot staminaSnapshot = await _firestore
          .collection('stamina_records')
          .where('coachId', isEqualTo: widget.coachId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
          
      if (staminaSnapshot.docs.isNotEmpty) return true;
      
      return false;
    } catch (e) {
      print('Error checking training records: $e');
      return false;
    }
  }
  
  Future<void> _loadStudentData(String studentId) async {
    setState(() {
      _isLoading = true;
      _studentRecords = [];
    });
    
    try {
      // Get student details
      DocumentSnapshot studentDoc = await _firestore
          .collection('users')
          .doc(studentId)
          .get();
          
      if (studentDoc.exists) {
        setState(() {
          _studentInfo = studentDoc.data() as Map<String, dynamic>;
        });
      }
      
      // Get all training records for this student
      List<Map<String, dynamic>> allRecords = [];
      
      // Get stamina records
      try {
        QuerySnapshot staminaSnapshot = await _firestore
            .collection('stamina_records')
            .where('coachId', isEqualTo: widget.coachId)
            .where('studentId', isEqualTo: studentId)
            .get();
        
        // Process stamina records
        for (var doc in staminaSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Parse time string to seconds for comparisons
          String timeString = data['time'] ?? '00:00.0';
          int totalSeconds = _parseTimeToSeconds(timeString);
          
          allRecords.add({
            'id': doc.id,
            'recordType': 'Stamina Training',
            'score': _calculateStaminaScore(totalSeconds),
            'time': timeString,
            'totalSeconds': totalSeconds,
            ...data,
          });
        }
      } catch (e) {
        print('Error loading stamina records: $e');
      }
      
      // Get balance records
      try {
        QuerySnapshot balanceSnapshot = await _firestore
            .collection('balance_records')
            .where('coachId', isEqualTo: widget.coachId)
            .where('studentId', isEqualTo: studentId)
            .get();
        
        // Process balance records
        for (var doc in balanceSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          allRecords.add({
            'id': doc.id,
            'recordType': 'Balance Training',
            'score': data['balanceScore'] ?? 0,
            ...data,
          });
        }
      } catch (e) {
        print('Error loading balance records: $e');
      }
      
      // Get spike records
      try {
        QuerySnapshot spikeSnapshot = await _firestore
            .collection('spike_records')
            .where('coachId', isEqualTo: widget.coachId)
            .where('studentId', isEqualTo: studentId)
            .get();
        
        // Process spike records
        for (var doc in spikeSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Calculate a score from successful spikes percentage
          int successfulSpikes = data['successfulSpikes'] ?? 0;
          int totalAttempts = data['totalAttempts'] ?? 1; // Avoid division by zero
          double successRate = totalAttempts > 0 ? successfulSpikes / totalAttempts : 0;
          int score = (successRate * 10).round();
          
          allRecords.add({
            'id': doc.id,
            'recordType': 'Spike Training',
            'score': score,
            'successRate': successRate,
            ...data,
          });
        }
      } catch (e) {
        print('Error loading spike records: $e');
      }
      
      // Sort records by date
      allRecords.sort((a, b) {
        final aTimestamp = a['timestamp'] as Timestamp?;
        final bTimestamp = b['timestamp'] as Timestamp?;
        if (aTimestamp == null || bTimestamp == null) return 0;
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
        SnackBar(content: Text('Error loading student data: ${e.toString().substring(0, min(50, e.toString().length))}')),
      );
    }
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
  
  // Convert stamina time to a performance score (higher is better)
  double _calculateStaminaScore(int totalSeconds) {
    const int benchmarkExcellent = 120; // 2 minutes is excellent performance
    const int benchmarkPoor = 300;      // 5 minutes is baseline performance
    
    // Cap to prevent negative scores for very long times
    int seconds = totalSeconds.clamp(0, 600);
    
    // For very fast times (under benchmark)
    if (seconds <= benchmarkExcellent) {
      // Score between 8-10 for excellent performance
      return 8.0 + ((benchmarkExcellent - seconds) / benchmarkExcellent) * 2.0;
    } 
    // For normal range times
    else if (seconds <= benchmarkPoor) {
      // Score between 4-8 for average performance
      return 4.0 + ((benchmarkPoor - seconds) / (benchmarkPoor - benchmarkExcellent)) * 4.0;
    } 
    // For slow times
    else {
      // Score between 0-4 for below average performance
      double score = 4.0 * (1 - ((seconds - benchmarkPoor) / (600 - benchmarkPoor)));
      return score.clamp(0.0, 4.0);
    }
  }
  
  Future<void> _generateAndDownloadPDF() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
// Wait for UI to render completely
await Future.delayed(const Duration(milliseconds: 500));

// Prepare training data summaries (declare before use)
Map<String, dynamic> trainingData = _prepareTrainingData();

// Capture charts with improved timing and error handling
Uint8List? balanceChartImage;
Uint8List? spikeChartImage;
Uint8List? staminaChartImage;

// Create fallback images for safety
Uint8List fallbackBalanceImage = await _createFallbackChartImage(
  'Balance Training', 
  trainingData['balanceCount'] > 0, 
  Colors.green
);

Uint8List fallbackSpikeImage = await _createFallbackChartImage(
  'Spike Training', 
  trainingData['spikeCount'] > 0, 
  Colors.purple
);

Uint8List fallbackStaminaImage = await _createFallbackChartImage(
  'Stamina Training', 
  trainingData['staminaCount'] > 0, 
  Colors.blue
);

// Try to capture balance chart
try {
  if (_balanceChartKey.currentContext != null) {
    balanceChartImage = await _captureChart(_balanceChartKey, 'Balance');
  }
} catch (e) {
  print('Balance chart capture failed: $e');
}

// Try to capture spike chart
try {
  if (_spikeChartKey.currentContext != null) {
    spikeChartImage = await _captureChart(_spikeChartKey, 'Spike');
  }
} catch (e) {
  print('Spike chart capture failed: $e');
}

// Try to capture stamina chart
try {
  if (_staminaChartKey.currentContext != null) {
    staminaChartImage = await _captureChart(_staminaChartKey, 'Stamina');
  }
} catch (e) {
  print('Stamina chart capture failed: $e');
}

// Use fallback images if needed
if (balanceChartImage == null || balanceChartImage.isEmpty) {
  print('Using fallback balance chart image');
  balanceChartImage = fallbackBalanceImage;
}

if (spikeChartImage == null || spikeChartImage.isEmpty) {
  print('Using fallback spike chart image');
  spikeChartImage = fallbackSpikeImage;
}

if (staminaChartImage == null || staminaChartImage.isEmpty) {
  print('Using fallback stamina chart image');
  staminaChartImage = fallbackStaminaImage;
}


      
      // Generate the PDF
      final pdf = pw.Document();
      
      // Add logo and header - with error handling for logo loading
      Uint8List logoData;
      try {
        final ByteData logoBytes = await rootBundle.load('assets/logo.png');
        logoData = logoBytes.buffer.asUint8List();
      } catch (e) {
        print('Logo loading failed: $e');
        logoData = Uint8List(0);
      }
      
      final studentName = _studentNames[_selectedStudentId] ?? 'Unknown Student';
      final reportDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
      
      // First Page - Cover and Summary (FIXED)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    logoData.isNotEmpty
                      ? pw.Image(pw.MemoryImage(logoData), width: 60, height: 60)
                      : pw.Container(
                          width: 60, 
                          height: 60, 
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue100,
                            borderRadius: pw.BorderRadius.circular(30),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'LOGO',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                          ),
                        ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Sepak Takraw Training Report',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Generated on: $reportDate',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Student Info
                pw.Text(
                  'Player Performance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 16),
                
                pw.Text(
                  'Player Information',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
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
                      _buildPdfInfoRow('Coach', widget.coachName),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Performance Summary
                pw.Text(
                  'Performance Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfInfoRow('Total Training Sessions', '${_studentRecords.length}'),
                      _buildPdfInfoRow('Balance Training Sessions', '${trainingData['balanceCount']}'),
                      _buildPdfInfoRow('Spike Training Sessions', '${trainingData['spikeCount']}'),
                      _buildPdfInfoRow('Stamina Training Sessions', '${trainingData['staminaCount']}'),
                      pw.SizedBox(height: 8),
                      _buildPdfInfoRow('Best Balance Score', 
                        '${(trainingData['bestBalanceScore'] as double).toStringAsFixed(1)}/10'),
                      _buildPdfInfoRow('Best Spike Success Rate', 
                        '${((trainingData['bestSpikeRate'] as double) * 100).toStringAsFixed(1)}%'),
                      _buildPdfInfoRow('Best Stamina Time', 
                        trainingData['bestStaminaTime'] as String),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Coach Notes (FIXED - ensure it fits on page)
                pw.Text(
                  'Coach Notes & Recommendations',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  width: double.infinity,
                  height: 100, // Fixed height to ensure it fits
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.topLeft,
                    child: pw.Text(
                      _notesController.text.isEmpty ? 'No notes provided.' : _notesController.text,
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Column(
                  children: [
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Generated by Takraw Thrill App',
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
                ),
              ],
            );
          },
        ),
      );
      
      // Second Page - Charts (FIXED - Show all three charts properly)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  'Performance Charts - $studentName',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 16),
                
                // Balance Chart
                pw.Text(
                  'Balance Performance',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 160, // Reduced height to fit all three charts
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: balanceChartImage != null && balanceChartImage.isNotEmpty
                    ? pw.Image(pw.MemoryImage(balanceChartImage), fit: pw.BoxFit.contain)
                    : pw.Center(
                        child: pw.Text(
                          'No balance training data available',
                          style: pw.TextStyle(color: PdfColors.grey600),
                        ),
                      ),
                ),
                pw.SizedBox(height: 16),
                
                // Spike Chart
                pw.Text(
                  'Spike Performance',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 160, // Reduced height to fit all three charts
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: spikeChartImage != null && spikeChartImage.isNotEmpty
                    ? pw.Image(pw.MemoryImage(spikeChartImage), fit: pw.BoxFit.contain)
                    : pw.Center(
                        child: pw.Text(
                          'No spike training data available',
                          style: pw.TextStyle(color: PdfColors.grey600),
                        ),
                      ),
                ),
                pw.SizedBox(height: 16),
                
                // Stamina Chart
                pw.Text(
                  'Stamina Performance',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 160, // Reduced height to fit all three charts
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: staminaChartImage != null && staminaChartImage.isNotEmpty
                    ? pw.Image(pw.MemoryImage(staminaChartImage), fit: pw.BoxFit.contain)
                    : pw.Center(
                        child: pw.Text(
                          'No stamina training data available',
                          style: pw.TextStyle(color: PdfColors.grey600),
                        ),
                      ),
                ),
                
                pw.Spacer(),
                
                // Performance Analysis
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Performance Analysis',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                
                pw.Container(
                  height: 60, // Fixed height for analysis text
                  child: pw.Text(
                    _generateAnalysisText(trainingData),
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                
                pw.SizedBox(height: 8),
                
                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by Takraw Thrill App',
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
      
      // Training Records Pages - Paginate with 20 records per page
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
          
          // Page number for footer (account for 2 initial pages)
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
                            performance = '${record['score'] ?? 'N/A'}/10';
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
                        }).toList(),
                      ],
                    ),
                    
                    pw.Spacer(),
                    pw.Divider(),
                    
                    // Footer
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Generated by Takraw Thrill App',
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

  void _debugPrintImageSize(String chartName, Uint8List? imageData) {
  if (imageData == null) {
    print('$chartName chart image is null');
  } else if (imageData.isEmpty) {
    print('$chartName chart image is empty (0 bytes)');
  } else {
    print('$chartName chart image captured: ${imageData.length} bytes');
  }
}

  
Future<Uint8List> _captureChart(GlobalKey key, String chartName) async {
  try {
    print('Attempting to capture $chartName chart...');
    
    // Find the render object
    RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    
    if (boundary == null) {
      print('$chartName chart boundary not found');
      return Uint8List(0);
    }
    
    // Wait for rendering to complete
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Check if the boundary needs to be painted
    if (boundary.debugNeedsPaint) {
      print('$chartName chart needs paint, waiting...');
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // Capture with higher pixel ratio for better quality
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      print('$chartName chart image data is null');
      return Uint8List(0);
    }
    
    final result = byteData.buffer.asUint8List();
    _debugPrintImageSize(chartName, result);
    return result;
  } catch (e) {
    print('Error capturing $chartName chart: $e');
    return Uint8List(0);
  }
}

Future<Uint8List> _createFallbackChartImage(String chartType, bool hasData, Color color) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final Size size = Size(500, 300);
  
  // Draw white background
  canvas.drawRect(
    Offset.zero & size, 
    Paint()..color = Colors.white
  );
  
  if (hasData) {
    // Draw chart outline
    canvas.drawRect(
      Rect.fromLTWH(50, 50, size.width - 100, size.height - 100),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
    );
    
    // Draw text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '$chartType Data',
        style: TextStyle(color: color, fontSize: 24),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2)
    );
  } else {
    // Draw "No data" message
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: 'No $chartType data available',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 24),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2)
    );
  }
  
  // Convert to image
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  return byteData?.buffer.asUint8List() ?? Uint8List(0);
}
  
  Map<String, dynamic> _prepareTrainingData() {
    // Count record types
    int balanceCount = 0;
    int spikeCount = 0;
    int staminaCount = 0;
    
    // Performance metrics
    double avgBalanceScore = 0;
    double bestBalanceScore = 0;
    double avgSpikeRate = 0;
    double bestSpikeRate = 0;
    String bestStaminaTime = '00:00.0';
    int bestStaminaSeconds = 9999;
    
    List<Map<String, dynamic>> balanceRecords = [];
    List<Map<String, dynamic>> spikeRecords = [];
    List<Map<String, dynamic>> staminaRecords = [];
    
    for (var record in _studentRecords) {
      String recordType = record['recordType'] ?? '';
      
      if (recordType == 'Balance Training') {
        balanceCount++;
        balanceRecords.add(record);
        double score = (record['score'] ?? 0).toDouble();
        avgBalanceScore += score;
        if (score > bestBalanceScore) bestBalanceScore = score;
      } 
      else if (recordType == 'Spike Training') {
        spikeCount++;
        spikeRecords.add(record);
        double rate = record['successRate'] ?? 0.0;
        avgSpikeRate += rate;
        if (rate > bestSpikeRate) bestSpikeRate = rate;
      } 
      else if (recordType == 'Stamina Training') {
        staminaCount++;
        staminaRecords.add(record);
        int seconds = record['totalSeconds'] ?? 0;
        if (seconds > 0 && seconds < bestStaminaSeconds) {
          bestStaminaSeconds = seconds;
          bestStaminaTime = record['time'] ?? '00:00.0';
        }
      }
    }
    
    // Calculate averages
    if (balanceCount > 0) avgBalanceScore /= balanceCount;
    if (spikeCount > 0) avgSpikeRate /= spikeCount;
    
    // Prepare recent records by type
    balanceRecords.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      if (aTimestamp == null || bTimestamp == null) return 0;
      return bTimestamp.compareTo(aTimestamp);
    });
    
    spikeRecords.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      if (aTimestamp == null || bTimestamp == null) return 0;
      return bTimestamp.compareTo(aTimestamp);
    });
    
    staminaRecords.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      if (aTimestamp == null || bTimestamp == null) return 0;
      return bTimestamp.compareTo(aTimestamp);
    });
    
    // Performance trend
    double balanceTrend = 0;
    double spikeTrend = 0;
    double staminaTrend = 0;
    
    if (balanceRecords.length >= 2) {
      double firstScore = (balanceRecords.last['score'] ?? 0).toDouble();
      double lastScore = (balanceRecords.first['score'] ?? 0).toDouble();
      balanceTrend = lastScore - firstScore;
    }
    
    if (spikeRecords.length >= 2) {
      double firstRate = spikeRecords.last['successRate'] ?? 0.0;
      double lastRate = spikeRecords.first['successRate'] ?? 0.0;
      spikeTrend = lastRate - firstRate;
    }
    
    if (staminaRecords.length >= 2) {
      int firstSeconds = staminaRecords.last['totalSeconds'] ?? 0;
      int lastSeconds = staminaRecords.first['totalSeconds'] ?? 0;
      staminaTrend = lastSeconds > 0 && firstSeconds > 0 
          ? (firstSeconds - lastSeconds) / firstSeconds.toDouble()
          : 0;
    }
    
    return {
      'balanceCount': balanceCount,
      'spikeCount': spikeCount,
      'staminaCount': staminaCount,
      'avgBalanceScore': avgBalanceScore,
      'bestBalanceScore': bestBalanceScore,
      'avgSpikeRate': avgSpikeRate,
      'bestSpikeRate': bestSpikeRate,
      'bestStaminaTime': bestStaminaTime,
      'bestStaminaSeconds': bestStaminaSeconds,
      'balanceRecords': balanceRecords,
      'spikeRecords': spikeRecords,
      'staminaRecords': staminaRecords,
      'balanceTrend': balanceTrend,
      'spikeTrend': spikeTrend,
      'staminaTrend': staminaTrend,
    };
  }
  
  String _generateAnalysisText(Map<String, dynamic> data) {
    List<String> analysis = [];
    
    // Add general assessment
    analysis.add('Performance Assessment:');
    
    // Balance analysis
    if (data['balanceCount'] > 0) {
      analysis.add('\nBalance Training:');
      analysis.add('• Completed ${data['balanceCount']} balance training sessions');
      analysis.add('• Best score: ${(data['bestBalanceScore'] as double).toStringAsFixed(1)}/10');
      analysis.add('• Average score: ${(data['avgBalanceScore'] as double).toStringAsFixed(1)}/10');
      
      if (data['balanceTrend'] > 0) {
        analysis.add('• Performance is improving (+${(data['balanceTrend'] as double).toStringAsFixed(1)} points)');
      } else if (data['balanceTrend'] < 0) {
        analysis.add('• Performance has declined (${(data['balanceTrend'] as double).toStringAsFixed(1)} points)');
      } else {
        analysis.add('• Performance has remained consistent');
      }
    }
    
    // Spike analysis
    if (data['spikeCount'] > 0) {
      analysis.add('\nSpike Training:');
      analysis.add('• Completed ${data['spikeCount']} spike training sessions');
      analysis.add('• Best success rate: ${((data['bestSpikeRate'] as double) * 100).toStringAsFixed(1)}%');
      analysis.add('• Average success rate: ${((data['avgSpikeRate'] as double) * 100).toStringAsFixed(1)}%');
      
      if (data['spikeTrend'] > 0) {
        analysis.add('• Success rate is improving (+${((data['spikeTrend'] as double) * 100).toStringAsFixed(1)}%)');
      } else if (data['spikeTrend'] < 0) {
        analysis.add('• Success rate has declined (${((data['spikeTrend'] as double) * 100).toStringAsFixed(1)}%)');
      } else {
        analysis.add('• Success rate has remained consistent');
      }
    }
    
    // Stamina analysis
    if (data['staminaCount'] > 0) {
      analysis.add('\nStamina Training:');
      analysis.add('• Completed ${data['staminaCount']} stamina training sessions');
      analysis.add('• Best time: ${data['bestStaminaTime']}');
      
      double staminaTrend = data['staminaTrend'] as double;
      if (staminaTrend > 0) {
        analysis.add('• Stamina performance is improving (${(staminaTrend * 100).toStringAsFixed(1)}% faster)');
      } else if (staminaTrend < 0) {
        analysis.add('• Stamina performance has declined (${(-staminaTrend * 100).toStringAsFixed(1)}% slower)');
      } else {
        analysis.add('• Stamina performance has remained consistent');
      }
    }
    
    return analysis.join('\n');
  }
  
  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentNames.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No students with training records found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Settings Section
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Report Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Student Selection
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Student',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedStudentId,
                                items: _studentNames.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStudentId = value;
                                    if (value != null) {
                                      _loadStudentData(value);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Coach Notes
                              TextField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Coach Notes & Recommendations',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Preview Section (only shown if student is selected)
                      if (_selectedStudentId != null && _studentRecords.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Report Preview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Student Info Summary
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Student: ${_studentNames[_selectedStudentId]}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Total Records: ${_studentRecords.length}'),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Performance Charts
                                const Text(
                                  'Performance Charts',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                
                                // Filter records by type for charts
                                Builder(
                                  builder: (context) {
                                    List<Map<String, dynamic>> balanceRecords = _studentRecords
                                        .where((r) => r['recordType'] == 'Balance Training')
                                        .toList();
                                        
                                    List<Map<String, dynamic>> spikeRecords = _studentRecords
                                        .where((r) => r['recordType'] == 'Spike Training')
                                        .toList();
                                        
                                    List<Map<String, dynamic>> staminaRecords = _studentRecords
                                        .where((r) => r['recordType'] == 'Stamina Training')
                                        .toList();
                                    
                                    // Sort records by date (oldest first for charts)
                                    for (var recordList in [balanceRecords, spikeRecords, staminaRecords]) {
                                      recordList.sort((a, b) {
                                        final aTimestamp = a['timestamp'] as Timestamp?;
                                        final bTimestamp = b['timestamp'] as Timestamp?;
                                        if (aTimestamp == null || bTimestamp == null) return 0;
                                        return aTimestamp.compareTo(bTimestamp);
                                      });
                                    }
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Balance chart - always show, even if empty
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Balance Score Progress',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              height: 200,
                                              child: RepaintBoundary(
                                                key: _balanceChartKey,
                                                child: balanceRecords.isEmpty
                                                  ? const Center(child: Text('No balance training records'))
                                                  : _buildLineChart(
                                                      balanceRecords,
                                                      (record) => (record['score'] ?? 0).toDouble(),
                                                      Colors.green,
                                                      0,
                                                      10,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                          ],
                                        ),
                                          
                                        // Spike chart - always show, even if empty
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Spike Success Rate',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              height: 200,
                                              child: RepaintBoundary(
                                                key: _spikeChartKey,
                                                child: spikeRecords.isEmpty
                                                  ? const Center(child: Text('No spike training records'))
                                                  : _buildLineChart(
                                                      spikeRecords,
                                                      (record) => (record['successRate'] ?? 0.0).toDouble(),
                                                      Colors.purple,
                                                      0,
                                                      1.0,
                                                      isPercentage: true
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                          ],
                                        ),
                                          
                                        // Stamina chart - always show, even if empty
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Stamina Performance Score',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              height: 200,
                                              child: RepaintBoundary(
                                                key: _staminaChartKey,
                                                child: staminaRecords.isEmpty
                                                  ? const Center(child: Text('No stamina training records'))
                                                  : _buildLineChart(
                                                      staminaRecords,
                                                      (record) => (record['score'] ?? 0).toDouble(),
                                                      Colors.blue,
                                                      0,
                                                      10,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Generate Report Button
                      if (_selectedStudentId != null)
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Generate PDF Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: _studentRecords.isEmpty 
                                ? null 
                                : _generateAndDownloadPDF,
                          ),
                        ),
                        
                      const SizedBox(height: 24),
                      
                      // Records count info
                      if (_selectedStudentId != null && _studentRecords.isNotEmpty)
                        Center(
                          child: Text(
                            'Total ${_studentRecords.length} training records will be included in the report',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildLineChart(
    List<Map<String, dynamic>> records,
    double Function(Map<String, dynamic>) getValue,
    Color color,
    double minY,
    double? maxY, {
    bool isPercentage = false,
  }) {
    // Handle the case of a single record
    if (records.length == 1) {
      final value = getValue(records[0]);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Single Data Point",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(
              isPercentage 
                ? "${(value * 100).toStringAsFixed(1)}%" 
                : "${value.toStringAsFixed(1)}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      );
    }
    
    // Handle multiple records with a chart
    if (records.length >= 2) {
      // Calculate max if not provided
      if (maxY == null) {
        maxY = 0;
        for (var record in records) {
          double value = getValue(record);
          if (value > maxY!) maxY = value;
        }
        maxY = (maxY! * 1.2); // Add some padding
      }
      
      return LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: maxY > 10 ? 30 : 1,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (isPercentage) {
                    return Text('${(value * 100).toInt()}%');
                  } else {
                    return Text('${value.toInt()}');
                  }
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  try {
                    var index = value.toInt();
                    if (index >= 0 && index < records.length && index % 3 == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('W${index + 1}'),
                      );
                    }
                  } catch (_) {}
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: records.length.toDouble() - 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                records.length,
                (i) => FlSpot(i.toDouble(), getValue(records[i])),
              ),
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
            ),
          ],
        ),
      );
    }
    
    // Handle the case of no records
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, color: Colors.grey.shade300, size: 48),
          const SizedBox(height: 16),
          Text(
            "No data available",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}*/