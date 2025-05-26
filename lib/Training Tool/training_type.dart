import 'package:flutter/material.dart';
import 'StudentListPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'training_course.dart';

class TrainingTypesPage extends StatefulWidget {
  final String userId;
  final String? displayName;

  const TrainingTypesPage({
    Key? key,
    required this.userId,
    this.displayName,
  }) : super(key: key);

  @override
  _TrainingTypesPageState createState() => _TrainingTypesPageState();
}

class _TrainingTypesPageState extends State<TrainingTypesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _hasActiveCourse = false;
  Map<String, dynamic>? _activeCourse;
  
  @override
  void initState() {
    super.initState();
    _checkActiveCourse();
  }
  
  Future<void> _checkActiveCourse() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      QuerySnapshot courseSnapshot = await _firestore
          .collection('training_courses')
          .where('coachId', isEqualTo: widget.userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (courseSnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = courseSnapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        DateTime startDate = (data['startDate'] as Timestamp).toDate();
        DateTime currentDate = DateTime.now();
        int daysSinceStart = currentDate.difference(startDate).inDays;
        int currentWeek = (daysSinceStart / 7).floor() + 1;
        
        setState(() {
          _hasActiveCourse = true;
          _activeCourse = {
            'id': doc.id,
            'courseName': data['courseName'],
            'startDate': startDate,
            'currentWeek': currentWeek,
            ...data,
          };
        });
      } else {
        setState(() {
          _hasActiveCourse = false;
          _activeCourse = null;
        });
      }
    } catch (e) {
      print('Error checking active course: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCourseUpdated() {
    _checkActiveCourse();
  }

  void _navigateToTraining(BuildContext context, String type) {
    // All training types now direct to StudentListPage with appropriate parameters
    String drillName;
    Color drillColor;
    
    switch (type) {
      case 'stamina':
        drillName = 'Stamina Training';
        drillColor = Colors.orange;
        break;
      case 'balance':
        drillName = 'Balance Training';
        drillColor = Colors.blue;
        break;
      case 'spike':
        drillName = 'Spike Training';
        drillColor = Colors.red;
        break;
      default:
        drillName = 'Training';
        drillColor = Colors.green;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentListPage(
          coachId: widget.userId,
          coachName: widget.displayName ?? '',
          drillName: drillName,
          drillColor: drillColor,
          courseData: _activeCourse,
        ),
      ),
    );
  }

  Widget _buildTrainingCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _hasActiveCourse ? onTap : () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please start a training course before accessing training modules')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(_hasActiveCourse ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: _hasActiveCourse ? color : Colors.grey,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _hasActiveCourse ? null : Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: _hasActiveCourse ? Colors.grey.shade700 : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: _hasActiveCourse ? Colors.grey : Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Types of Training'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Manager
                    TrainingCourseManager(
                      coachId: widget.userId,
                      coachName: widget.displayName ?? '',
                      onCourseUpdated: _onCourseUpdated,
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Header
                    Text(
                      'Available Training Modules',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _hasActiveCourse 
                          ? 'Choose a training category to set up exercises for your players'
                          : 'Start a training course above to access training modules',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Training Type Cards
                    Expanded(
                      child: ListView(
                        children: [
                          _buildTrainingCard(
                            context,
                            title: 'Stamina Training',
                            description: 'Exercises to improve player endurance and overall fitness.',
                            icon: Icons.directions_run,
                            color: Colors.orange,
                            onTap: () => _navigateToTraining(context, 'stamina'),
                          ),
                          SizedBox(height: 16),
                          _buildTrainingCard(
                            context,
                            title: 'Balance Ball Training',
                            description: 'Techniques to enhance ball control and balance.',
                            icon: Icons.sports_volleyball,
                            color: Colors.blue,
                            onTap: () => _navigateToTraining(context, 'balance'),
                          ),
                          SizedBox(height: 16),
                          _buildTrainingCard(
                            context,
                            title: 'Spike Ball Training',
                            description: 'Offensive techniques for powerful and accurate spikes.',
                            icon: Icons.sports_handball,
                            color: Colors.red,
                            onTap: () => _navigateToTraining(context, 'spike'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}