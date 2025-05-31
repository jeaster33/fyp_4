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

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();
  final TextEditingController _secondaryEmailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();
  String _selectedRole = '';

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
            primaryColor: Color(0xFF667eea),
            colorScheme: ColorScheme.light(primary: Color(0xFF667eea)),
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF667eea)),
                  SizedBox(height: 15),
                  Text('Creating user...', style: TextStyle(color: Color(0xFF2d3748))),
                ],
              ),
            ),
          );
        },
      );
      
      if (email.isEmpty || password.isEmpty || role.isEmpty || icNumber.isEmpty || 
          phoneNumber.isEmpty || fullName.isEmpty || username.isEmpty) {
        Navigator.pop(context);
        _showMessage('Please fill all required fields', isError: true);
        return;
      }
      
      if (role != 'student' && role != 'teacher' && role != 'admin') {
        Navigator.pop(context);
        _showMessage('Role must be student, teacher, or admin', isError: true);
        return;
      }
      
      bool usernameAlreadyExists = await _usernameExists(username);
      if (usernameAlreadyExists) {
        Navigator.pop(context);
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

      Navigator.pop(context);
      _showMessage('User registered successfully!', isError: false);
      _clearForm();
      
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Failed to register user: $e', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Color(0xFF43e97b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              Color(0xFF667eea),
              Color(0xFFf093fb).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _signOut(context),
                  ),
                ],
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
                                color: Color(0xFF2d3748),
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
                              prefixIcon: Icon(Icons.badge, color: Color(0xFF667eea)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              labelStyle: TextStyle(color: Color(0xFF667eea)),
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
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF667eea)),
                                  suffixIcon: Icon(Icons.arrow_drop_down, color: Color(0xFF667eea)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  labelStyle: TextStyle(color: Color(0xFF667eea)),
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
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF667eea).withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
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
                            child: Text(
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
                ),
              ),
            ],
          ),
        ),
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
          prefixIcon: Icon(icon, color: Color(0xFF667eea)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(color: Color(0xFF667eea)),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    _icNumberController.dispose();
    _secondaryEmailController.dispose();
    _phoneNumberController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}