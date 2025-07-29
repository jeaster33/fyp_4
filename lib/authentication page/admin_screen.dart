import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();
  final TextEditingController _secondaryEmailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController(); // Course name controller
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();
  String _selectedRole = '';
  bool _isLoading = false;
  late TabController _tabController;

  // Statistics
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _activeCourses = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // UPDATED: Back to 4 tabs
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    _icNumberController.dispose();
    _secondaryEmailController.dispose();
    _phoneNumberController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _courseNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _loadingStats = true;
    });

    try {
      // Get students count
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // Get teachers count
      QuerySnapshot teachersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      // Get active courses count
      QuerySnapshot coursesSnapshot = await _firestore
          .collection('training_courses')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _totalStudents = studentsSnapshot.docs.length;
        _totalTeachers = teachersSnapshot.docs.length;
        _activeCourses = coursesSnapshot.docs.length;
        _loadingStats = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _loadingStats = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  Future<bool> _usernameExists(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // UPDATED: Simplified start training course function
  Future<void> _startTrainingCourse() async {
    if (_courseNameController.text.isEmpty) {
      _showMessage('Please enter a course name', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if there's already an active course (global check)
      QuerySnapshot existingCourse = await _firestore
          .collection('training_courses')
          .where('isActive', isEqualTo: true)
          .get();

      if (existingCourse.docs.isNotEmpty) {
        _showMessage('There is already an active training course. Please end it first.', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create new training course without coach assignment
      await _firestore.collection('training_courses').add({
        'courseName': _courseNameController.text.trim(),
        'startDate': FieldValue.serverTimestamp(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
        'createdByRole': 'admin',
      });

      _showMessage('Training course started successfully!', isError: false);
      _courseNameController.clear();
      _loadStatistics(); // Refresh stats

    } catch (e) {
      _showMessage('Error starting training course: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> createUserWithRole(
    String email, 
    String password, 
    String role, 
    String icNumber, 
    DateTime dateOfBirth, 
    String secondaryEmail, 
    String phoneNumber,
    String fullName,
    String username
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      if (email.isEmpty || password.isEmpty || role.isEmpty || icNumber.isEmpty || 
          phoneNumber.isEmpty || fullName.isEmpty || username.isEmpty) {
        _showMessage('Please fill all required fields', isError: true);
        return;
      }
      
      if (role != 'student' && role != 'teacher' && role != 'admin') {
        _showMessage('Role must be student, teacher, or admin', isError: true);
        return;
      }
      
      bool usernameAlreadyExists = await _usernameExists(username);
      if (usernameAlreadyExists) {
        _showMessage('Username already exists. Please choose a different one', isError: true);
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'icNumber': icNumber,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'secondaryEmail': secondaryEmail,
        'phoneNumber': phoneNumber,
        'fullName': fullName,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'profileImageUrl': '',
      });

      _showMessage('User registered successfully!', isError: false);
      _clearForm();
      _loadStatistics(); // Refresh stats
      
    } catch (e) {
      _showMessage('Failed to register user: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId, String userEmail, String role) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete User'),
          content: Text('Are you sure you want to delete this $role?\n\nEmail: $userEmail\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Delete user document from Firestore
        await _firestore.collection('users').doc(userId).delete();
        
        _showMessage('User deleted successfully from database', isError: false);
        _loadStatistics(); // Refresh stats
        
      } catch (e) {
        _showMessage('Error deleting user: $e', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _endTrainingCourse(String courseId, String courseName) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('End Training Course'),
          content: Text('Are you sure you want to end the course:\n\n"$courseName"\n\nThis will mark the course as completed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('End Course'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Update course to inactive
        await _firestore.collection('training_courses').doc(courseId).update({
          'isActive': false,
          'endDate': FieldValue.serverTimestamp(),
          'endedBy': _auth.currentUser?.uid,
          'endedByRole': 'admin',
        });

        _showMessage('Training course ended successfully', isError: false);
        _loadStatistics(); // Refresh stats
        
      } catch (e) {
        _showMessage('Error ending course: $e', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFEF4444) : Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _roleController.clear();
    _icNumberController.clear();
    _secondaryEmailController.clear();
    _phoneNumberController.clear();
    _fullNameController.clear();
    _usernameController.clear();
    setState(() {
      _selectedRole = '';
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    });
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SplashScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showMessage('Error signing out: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - Matching teacher home screen style
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E40AF),
                      Color(0xFF3B82F6),
                      Color(0xFF60A5FA)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 25,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'ADMIN PANEL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'System Administrator',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Takraw Thrill Management',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _signOut(context),
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFEF4444).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(Icons.logout, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Statistics
                    Row(
                      children: [
                        _buildSportStat(
                          _loadingStats ? '...' : '$_totalStudents',
                          'Students',
                          Color(0xFF10B981),
                        ),
                        SizedBox(width: 16),
                        _buildSportStat(
                          _loadingStats ? '...' : '$_totalTeachers',
                          'Teachers',
                          Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 16),
                        _buildSportStat(
                          _loadingStats ? '...' : '$_activeCourses',
                          'Courses',
                          Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Bar - UPDATED: Merged course tabs
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF3B82F6),
                  unselectedLabelColor: Colors.grey,
                  indicator: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tabs: [
                    Tab(icon: Icon(Icons.person_add), text: 'Add User'),
                    Tab(icon: Icon(Icons.people), text: 'Students'),
                    Tab(icon: Icon(Icons.school), text: 'Teachers'),
                    Tab(icon: Icon(Icons.class_), text: 'Courses'), // UPDATED: Merged tab
                  ],
                ),
              ),

              // Tab Content - UPDATED: Merged course content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAddUserTab(),
                    _buildUsersListTab('student'),
                    _buildUsersListTab('teacher'),
                    _buildCoursesTab(), // UPDATED: Combined course management
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddUserTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text(
                  'Register New User',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            _buildTextField(_fullNameController, 'Full Name', Icons.person, isRequired: true),
            _buildTextField(_usernameController, 'Username', Icons.account_circle, isRequired: true),
            _buildTextField(_emailController, 'Email', Icons.email, isRequired: true, keyboardType: TextInputType.emailAddress),
            _buildTextField(_passwordController, 'Password', Icons.lock, isRequired: true, isPassword: true),
            
            // Role dropdown
            Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Role *',
                  prefixIcon: Icon(Icons.badge, color: Color(0xFF3B82F6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  labelStyle: TextStyle(color: Color(0xFF3B82F6)),
                ),
                value: _selectedRole.isEmpty ? null : _selectedRole,
                items: [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    _roleController.text = value;
                  });
                },
              ),
            ),
            
            _buildTextField(_icNumberController, 'IC Number', Icons.credit_card, isRequired: true),
            
            // Date picker
            Container(
              margin: EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
                      suffixIcon: Icon(Icons.arrow_drop_down, color: Color(0xFF3B82F6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      labelStyle: TextStyle(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ),
              ),
            ),
            
            _buildTextField(_phoneNumberController, 'Phone Number', Icons.phone, isRequired: true, keyboardType: TextInputType.phone),
            _buildTextField(_secondaryEmailController, 'Secondary Email', Icons.alternate_email, keyboardType: TextInputType.emailAddress),
            
            SizedBox(height: 24),
            
            // Register button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  createUserWithRole(
                    _emailController.text,
                    _passwordController.text,
                    _roleController.text,
                    _icNumberController.text,
                    _selectedDate,
                    _secondaryEmailController.text,
                    _phoneNumberController.text,
                    _fullNameController.text,
                    _usernameController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'REGISTER USER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            
            SizedBox(height: 12),
            Text(
              '* Required fields',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersListTab(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  role == 'student' ? Icons.school : Icons.person,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No ${role}s found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: role == 'student' 
                          ? [Color(0xFF10B981), Color(0xFF059669)]
                          : [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    role == 'student' ? Icons.school : Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  data['fullName'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      '@${data['username'] ?? 'unknown'}',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      data['email'] ?? 'No email',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(
                    doc.id,
                    data['email'] ?? 'Unknown',
                    role,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // UPDATED: Combined courses tab with start and management functionality
  Widget _buildCoursesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Course Management Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.class_, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Course Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Manage training courses - Only one course can be active at a time',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 24),
                
                // Check if there's an active course
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('training_courses')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    bool hasActiveCourse = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    
                    if (hasActiveCourse) {
                      // Show active course info and end button
                      DocumentSnapshot courseDoc = snapshot.data!.docs.first;
                      Map<String, dynamic> courseData = courseDoc.data() as Map<String, dynamic>;
                      DateTime startDate = (courseData['startDate'] as Timestamp).toDate();
                      int daysSinceStart = DateTime.now().difference(startDate).inDays;
                      int currentWeek = (daysSinceStart / 7).floor() + 1;
                      
                      return Column(
                        children: [
                          // Active Course Display
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF10B981).withOpacity(0.1),
                                  Color(0xFF059669).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.school, color: Colors.white, size: 20),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Active Training Course',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                          Text(
                                            courseData['courseName'] ?? 'Unknown Course',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF3B82F6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Color(0xFF3B82F6).withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        'Week $currentWeek',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3B82F6),
                                          fontSize: 12,
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
                                      'Started: ${DateFormat('MMM d, yyyy').format(startDate)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // End Course Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFEF4444).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _endTrainingCourse(
                                courseDoc.id,
                                courseData['courseName'] ?? 'Unknown Course',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(Icons.stop_circle, color: Colors.white),
                              label: Text(
                                'END TRAINING COURSE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Show start new course form
                      return Column(
                        children: [
                          // No Active Course Display
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFF59E0B).withOpacity(0.1),
                                  Color(0xFFD97706).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.info, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No Active Course',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      Text(
                                        'Start a new training course to begin training sessions',
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
                          ),
                          SizedBox(height: 24),
                          
                          // Course Name Input
                          _buildTextField(_courseNameController, 'Course Name', Icons.school, isRequired: true),
                          
                          // Start Course Button
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF10B981).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _startTrainingCourse,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.play_circle_fill, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'START TRAINING COURSE',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                
                SizedBox(height: 24),
                
                // Course Rules Info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Course Management Rules',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Only one training course can be active at a time\n'
                        '• All teachers and students can access the active course\n'
                        '• End the current course before starting a new one\n'
                        '• Course data is preserved when ended',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Course History Section (Optional)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.history, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Course History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Show ended courses
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('training_courses')
                      .where('isActive', isEqualTo: false)
                      .orderBy('endDate', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No completed courses yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        DateTime? endDate = data['endDate'] != null 
                            ? (data['endDate'] as Timestamp).toDate() 
                            : null;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['courseName'] ?? 'Unknown Course',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              if (endDate != null)
                                Text(
                                  'Ended ${DateFormat('MMM d').format(endDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isRequired = false,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: Icon(icon, color: Color(0xFF3B82F6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }
}