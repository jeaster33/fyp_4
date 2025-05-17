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

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  // Function to pick date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
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

  // Function to check if username already exists
  Future<bool> _usernameExists(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Function to create a user with a specific role and additional info
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      // Validate input fields
      if (email.isEmpty || password.isEmpty || role.isEmpty || icNumber.isEmpty || 
          phoneNumber.isEmpty || fullName.isEmpty || username.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
      
      // Validate role
      if (role != 'student' && role != 'teacher' && role != 'admin') {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role must be student, teacher, or admin')),
        );
        return;
      }
      
      // Check if username already exists
      bool usernameAlreadyExists = await _usernameExists(username);
      if (usernameAlreadyExists) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username already exists. Please choose a different one')),
        );
        return;
      }

      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create Firestore entry for the user with additional fields
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
        'profileImageUrl': '', // Empty for now, can be updated later
      });

      Navigator.pop(context); // Close loading dialog
      print('User created with role: $role');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User registered successfully')),
      );
      
      // Clear form fields after successful registration
      _emailController.clear();
      _passwordController.clear();
      _roleController.clear();
      _icNumberController.clear();
      _secondaryEmailController.clear();
      _phoneNumberController.clear();
      _fullNameController.clear();
      _usernameController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error creating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register user: $e')),
      );
    }
  }

  // Function to handle user sign out
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Register New User',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            // Full Name field
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 12),
            
            // Username field
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.account_circle),
                hintText: 'Unique username for login',
              ),
            ),
            SizedBox(height: 12),
            
            // Email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            
            // Password field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.lock),
                helperText: 'Minimum 6 characters',
              ),
              obscureText: true,
            ),
            SizedBox(height: 12),
            
            // Role field with dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Role *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.badge),
              ),
              items: ['student', 'teacher', 'admin'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.charAt(0).toUpperCase() + value.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                _roleController.text = value!;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a role';
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            
            // IC Number field
            TextField(
              controller: _icNumberController,
              decoration: InputDecoration(
                labelText: 'IC Number *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            SizedBox(height: 12),
            
            // Date of Birth field
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            
            // Phone Number field
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            
            // Secondary Email field
            TextField(
              controller: _secondaryEmailController,
              decoration: InputDecoration(
                labelText: 'Secondary Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.alternate_email),
                hintText: 'Optional',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 24),
            
            // Register button
            SizedBox(
              width: double.infinity,
              height: 50,
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
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Register User',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '* Required fields',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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

// Extension method to capitalize first letter
extension StringExtension on String {
  String charAt(int index) {
    if (this.isEmpty) return '';
    if (index < 0 || index >= this.length) return '';
    return this[index];
  }
}