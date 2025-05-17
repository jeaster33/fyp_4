import 'package:flutter/material.dart';

class BalanceBallTrainingPage extends StatelessWidget {
  final String userId;
  final String? displayName;

  const BalanceBallTrainingPage({
    Key? key,
    required this.userId,
    this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Balance Ball Training'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildTechniqueList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
        onPressed: () {
          // TODO: Implement adding new balance technique
          _showAddTechniqueDialog(context);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balance Ball Training',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Techniques to enhance ball control and balance',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade800),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Balance and ball control are fundamental skills in Sepak Takraw. These exercises help players develop precise control and stability.',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechniqueList(BuildContext context) {
    // Static list of techniques for demonstration
    List<Map<String, dynamic>> techniques = [
      {
        'title': 'Single Leg Ball Juggling',
        'difficulty': 'Intermediate',
        'description': 'Balance on one leg while keeping the ball in the air using only the raised foot. Practice with both legs.',
        'videoUrl': 'https://example.com/balance1', // Placeholder URL
      },
      {
        'title': 'Circle Drill',
        'difficulty': 'Beginner',
        'description': 'Players form a circle and pass the ball to each other using different parts of the foot without letting it touch the ground.',
        'videoUrl': 'https://example.com/balance2', // Placeholder URL
      },
      {
        'title': 'Ball Stalling Practice',
        'difficulty': 'Advanced',
        'description': 'Balance the ball on different parts of the foot for increasing durations. Start with 5 seconds and gradually increase.',
        'videoUrl': 'https://example.com/balance3', // Placeholder URL
      },
      {
        'title': 'Balance Board Control',
        'difficulty': 'Advanced',
        'description': 'Stand on a balance board while performing ball control exercises to enhance stability and proprioception.',
        'videoUrl': 'https://example.com/balance4', // Placeholder URL
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balance Techniques',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...techniques.map((technique) => _buildTechniqueCard(context, technique)).toList(),
      ],
    );
  }

  Widget _buildTechniqueCard(BuildContext context, Map<String, dynamic> technique) {
    Color difficultyColor;
    
    switch (technique['difficulty']) {
      case 'Beginner':
        difficultyColor = Colors.green;
        break;
      case 'Intermediate':
        difficultyColor = Colors.orange;
        break;
      case 'Advanced':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.blue;
    }

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
                    technique['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    technique['difficulty'],
                    style: TextStyle(
                      color: difficultyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              technique['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.play_circle_outline),
                  label: Text('Watch Video'),
                  onPressed: () {
                    // TODO: Implement video playback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Video playback will be implemented soon')),
                    );
                  },
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // TODO: Implement edit functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
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

  void _showAddTechniqueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Technique'),
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