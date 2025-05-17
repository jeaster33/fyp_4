import 'package:flutter/material.dart';

class StaminaTrainingPage extends StatelessWidget {
  final String userId;
  final String? displayName;

  const StaminaTrainingPage({
    Key? key,
    required this.userId,
    this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stamina Training'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildExerciseList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.add),
        onPressed: () {
          // TODO: Implement adding new stamina exercise
          _showAddExerciseDialog(context);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stamina Training',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Exercises to improve endurance and fitness for Sepak Takraw players',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade800),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stamina is crucial for maintaining high performance throughout a match. These exercises will help players build endurance.',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList(BuildContext context) {
    // For now, we'll use a static list of exercises
    // In a real app, you'd fetch these from Firebase
    List<Map<String, dynamic>> exercises = [
      {
        'title': 'High-Intensity Interval Training',
        'duration': '15 minutes',
        'description': 'Alternating between 30 seconds of max effort and 15 seconds of rest. Excellent for building cardiovascular endurance.',
      },
      {
        'title': 'Circuit Training',
        'duration': '20 minutes',
        'description': 'Rotate through 5 stations: jumping jacks, mountain climbers, high knees, burpees, and jump squats. 40 seconds work, 20 seconds rest.',
      },
      {
        'title': 'Shuttle Runs',
        'duration': '10 minutes',
        'description': 'Set up cones at 5m, 10m, and 15m. Sprint to each cone and back to start. 5 sets with 60 seconds rest between each set.',
      },
      {
        'title': 'Ladder Drills',
        'duration': '12 minutes',
        'description': 'Use an agility ladder for various footwork patterns, focusing on quick and precise movements.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Exercises',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...exercises.map((exercise) => _buildExerciseCard(context, exercise)).toList(),
      ],
    );
  }

  Widget _buildExerciseCard(BuildContext context, Map<String, dynamic> exercise) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    exercise['duration'],
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              exercise['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('Edit'),
                  onPressed: () {
                    // TODO: Implement edit functionality
                  },
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(Icons.delete, size: 18),
                  label: Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    // TODO: Implement delete functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Exercise'),
        content: Text('This feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}