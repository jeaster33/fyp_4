import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';

class TeacherProfilePage extends StatefulWidget {
  final Function? onProfileUpdated;

  const TeacherProfilePage({
    super.key,
    this.onProfileUpdated,
  });

  @override
  _TeacherProfilePageState createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = true;
  bool _isEditingProfile = false;

  // User data
  String _fullName = '';
  String _email = '';
  String _username = '';
  String _icNumber = '';
  String _phoneNumber = '';
  String _secondaryEmail = '';
  DateTime? _dateOfBirth;
  String _profileImageUrl = '';
  String _role = 'teacher';
  String _specialization = '';

  // Controllers for editing
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _secondaryEmailController =
      TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          // Set state with user data
          setState(() {
            _fullName = data['fullName'] ?? '';
            _email = data['email'] ?? user.email ?? '';
            _username = data['username'] ?? '';
            _icNumber = data['icNumber'] ?? '';
            _phoneNumber = data['phoneNumber'] ?? '';
            _secondaryEmail = data['secondaryEmail'] ?? '';
            _profileImageUrl = data['profileImageUrl'] ?? '';
            _role = data['role'] ?? 'teacher';
            _specialization = data['specialization'] ?? 'Sepak Takraw Coach';

            // Convert Firestore timestamp to DateTime
            if (data['dateOfBirth'] != null) {
              _dateOfBirth = (data['dateOfBirth'] as Timestamp).toDate();
            }

            // Initialize controllers
            _fullNameController.text = _fullName;
            _phoneNumberController.text = _phoneNumber;
            _secondaryEmailController.text = _secondaryEmail;
            _specializationController.text = _specialization;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // FIXED PICK IMAGE METHOD
  Future<void> _pickImage() async {
    try {
      // Show a modal bottom sheet with options
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing image picker options: $e');
    }
  }

  // FIXED IMAGE UPLOAD METHOD
// Change this in your TeacherProfilePage
  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      setState(() => _isLoading = true);

      // Updated path to match your current rules
      final ref = FirebaseStorage.instance
          .ref()
          .child('users') // Changed
          .child(_auth.currentUser!.uid) // Changed
          .child('profile_picture.jpg'); // Changed

      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'profileImageUrl': url});

      setState(() {
        _profileImageUrl = url;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_fullNameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full name and phone number are required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String uid = _auth.currentUser?.uid ?? '';

      // Update user profile
      await _firestore.collection('users').doc(uid).update({
        'fullName': _fullNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'secondaryEmail': _secondaryEmailController.text,
        'specialization': _specializationController.text,
      });

      // Update local state
      setState(() {
        _fullName = _fullNameController.text;
        _phoneNumber = _phoneNumberController.text;
        _secondaryEmail = _secondaryEmailController.text;
        _specialization = _specializationController.text;
        _isEditingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );

      // Notify parent widget if needed
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _secondaryEmailController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coach Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditingProfile)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditingProfile = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture section
                  Center(
                    child: Stack(
                      children: [
                        // Profile picture
                        Hero(
                          tag: 'profilePicture',
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImageUrl.isNotEmpty
                                ? NetworkImage(_profileImageUrl)
                                : null,
                            child: _profileImageUrl.isEmpty
                                ? Icon(
                                    Icons.sports,
                                    color: Color(0xFF3B82F6),
                                    size: 60,
                                  )
                                : null,
                          ),
                        ),
                        // Edit icon
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Profile information
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Divider(),
                          _isEditingProfile
                              ? _buildEditableField(
                                  'Full Name', _fullNameController)
                              : _buildProfileField('Full Name', _fullName),
                          _buildProfileField('Username', _username),
                          _buildProfileField('Email', _email),
                          _isEditingProfile
                              ? _buildEditableField(
                                  'Specialization', _specializationController)
                              : _buildProfileField(
                                  'Specialization', _specialization),
                          _isEditingProfile
                              ? _buildEditableField(
                                  'Phone Number', _phoneNumberController)
                              : _buildProfileField(
                                  'Phone Number', _phoneNumber),
                          _buildProfileField('IC Number', _icNumber),
                          _buildProfileField(
                              'Date of Birth',
                              _dateOfBirth != null
                                  ? DateFormat('dd MMMM yyyy')
                                      .format(_dateOfBirth!)
                                  : 'Not specified'),
                          _isEditingProfile
                              ? _buildEditableField(
                                  'Secondary Email', _secondaryEmailController,
                                  isOptional: true)
                              : _secondaryEmail.isNotEmpty
                                  ? _buildProfileField(
                                      'Secondary Email', _secondaryEmail)
                                  : Container(),
                          _buildProfileField(
                              'Role',
                              _role.charAt(0).toUpperCase() +
                                  _role.substring(1)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Coach Statistics Card
                  if (!_isEditingProfile)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coaching Statistics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('12', 'Sessions'),
                                _buildStatItem('8', 'Students'),
                                _buildStatItem('3', 'Upcoming'),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('98%', 'Attendance'),
                                _buildStatItem('85%', 'Progress'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 24),

                  // Save/Cancel buttons when editing
                  if (_isEditingProfile)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              // Reset controllers to original values
                              _fullNameController.text = _fullName;
                              _phoneNumberController.text = _phoneNumber;
                              _secondaryEmailController.text = _secondaryEmail;
                              _specializationController.text = _specialization;
                              _isEditingProfile = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                          child: Text('Save Changes'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isOptional ? ' (Optional)' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// Extension method to capitalize first letter
extension StringExtension on String {
  String charAt(int index) {
    if (isEmpty) return '';
    if (index < 0 || index >= length) return '';
    return this[index];
  }
}
