import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  final Function? onProfileUpdated;

  const ProfilePage({
    Key? key,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
  String _role = 'student';

  // Controllers for editing
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _secondaryEmailController = TextEditingController();

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
        DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          setState(() {
            _fullName = data['fullName'] ?? '';
            _email = data['email'] ?? user.email ?? '';
            _username = data['username'] ?? '';
            _icNumber = data['icNumber'] ?? '';
            _phoneNumber = data['phoneNumber'] ?? '';
            _secondaryEmail = data['secondaryEmail'] ?? '';
            _profileImageUrl = data['profileImageUrl'] ?? '';
            _role = data['role'] ?? 'student';

            if (data['dateOfBirth'] != null) {
              _dateOfBirth = (data['dateOfBirth'] as Timestamp).toDate();
            }

            _fullNameController.text = _fullName;
            _phoneNumberController.text = _phoneNumber;
            _secondaryEmailController.text = _secondaryEmail;
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        String uid = _auth.currentUser?.uid ?? '';
        File imageFile = File(image.path);
        String fileName = 'profile_images/$uid.jpg';

        await _storage.ref(fileName).putFile(imageFile);
        String downloadUrl = await _storage.ref(fileName).getDownloadURL();

        await _firestore.collection('users').doc(uid).update({
          'profileImageUrl': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
        }
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_fullNameController.text.isEmpty || _phoneNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Full name and phone number are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String uid = _auth.currentUser?.uid ?? '';

      await _firestore.collection('users').doc(uid).update({
        'fullName': _fullNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'secondaryEmail': _secondaryEmailController.text,
      });

      setState(() {
        _fullName = _fullNameController.text;
        _phoneNumber = _phoneNumberController.text;
        _secondaryEmail = _secondaryEmailController.text;
        _isEditingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile'),
          backgroundColor: Colors.red,
        ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Color(0xFF10B981),
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
          ? Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
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
                                    Icons.sports_handball,
                                    size: 60,
                                    color: Color(0xFF10B981),
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
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF10B981).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
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
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Divider(color: Color(0xFF10B981).withOpacity(0.3)),
                          _isEditingProfile
                              ? _buildEditableField('Full Name', _fullNameController)
                              : _buildProfileField('Full Name', _fullName),
                          _buildProfileField('Username', '@$_username'),
                          _buildProfileField('Email', _email),
                          _isEditingProfile
                              ? _buildEditableField('Phone Number', _phoneNumberController)
                              : _buildProfileField('Phone Number', _phoneNumber),
                          _buildProfileField('IC Number', _icNumber),
                          _buildProfileField(
                              'Date of Birth',
                              _dateOfBirth != null
                                  ? DateFormat('dd MMMM yyyy').format(_dateOfBirth!)
                                  : 'Not specified'),
                          _isEditingProfile
                              ? _buildEditableField('Secondary Email', _secondaryEmailController, isOptional: true)
                              : _secondaryEmail.isNotEmpty
                                  ? _buildProfileField('Secondary Email', _secondaryEmail)
                                  : Container(),
                          _buildProfileField(
                              'Role',
                              _role.charAt(0).toUpperCase() + _role.substring(1)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Save/Cancel buttons when editing
                  if (_isEditingProfile)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _fullNameController.text = _fullName;
                                _phoneNumberController.text = _phoneNumber;
                                _secondaryEmailController.text = _secondaryEmail;
                                _isEditingProfile = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red, width: 2),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Text('Save Changes'),
                          ),
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
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value.isNotEmpty ? value : 'Not specified',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: value.isNotEmpty ? Color(0xFF1F2937) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isOptional ? ' (Optional)' : ''),
          labelStyle: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Color(0xFF10B981).withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Color(0xFF10B981).withOpacity(0.3)),
          ),
        ),
      ),
    );
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