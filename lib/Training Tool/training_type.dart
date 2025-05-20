import 'package:flutter/material.dart';
import 'StudentListPage.dart';

class TrainingTypesPage extends StatelessWidget {
  final String userId;
  final String? displayName;

  const TrainingTypesPage({
    Key? key,
    required this.userId,
    this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Types of Training'),
        backgroundColor: Colors.green,
      ),
      body: Container(
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
              // Header
              Text(
                'Select Training Type',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a training category to set up exercises for your players',
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
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
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
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
          coachId: userId,
          coachName: displayName ?? '',
          drillName: drillName,
          drillColor: drillColor,
        ),
      ),
    );
  }
}