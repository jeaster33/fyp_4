import 'package:flutter/material.dart';

class SpikeBallTrainingPage extends StatelessWidget {
  final String userId;
  final String? displayName;

  const SpikeBallTrainingPage({
    Key? key,
    required this.userId,
    this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spike Ball Training'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildDrillsList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: Icon(Icons.add),
        onPressed: () {
          // TODO: Implement adding new spike drill
          _showAddDrillDialog(context);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spike Ball Training',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Offensive techniques for powerful and accurate spikes',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red.shade800),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Spiking is a critical offensive skill in Sepak Takraw. These drills help players develop power, accuracy, and technique.',
                  style: TextStyle(
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrillsList(BuildContext context) {
    // Static list of spike drills for demonstration
    List<Map<String, dynamic>> drills = [
      {
        'title': 'Basic Spike Form Practice',
        'focus': 'Technique',
        'description': 'Work on proper body positioning and follow-through without the ball. Focus on hip rotation and foot positioning.',
        'equipment': 'None',
      },
      {
        'title': 'Target Practice',
        'focus': 'Accuracy',
        'description': 'Set up targets on the opposite court. Players practice spiking to hit specific targets from different positions.',
        'equipment': 'Targets, Sepak Takraw balls',
      },
      {
        'title': 'Spike Height Drill',
        'focus': 'Power',
        'description': 'Practice spiking from progressively higher tosses to develop vertical leap and timing.',
        'equipment': 'Sepak Takraw balls, Measuring tape',
      },
      {
        'title': 'Defensive Spike Drill',
        'focus': 'Strategy',
        'description': 'Practice spiking against active blockers. Focus on finding gaps and varying spike angles.',
        'equipment': 'Sepak Takraw balls, Blocking pads',
      },
      {
        'title': 'Quick Reaction Spike',
        'focus': 'Speed',
        'description': 'Coach sets inconsistent tosses that require players to quickly adjust their position and spike technique.',
        'equipment': 'Sepak Takraw balls',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spiking Drills',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...drills.map((drill) => _buildDrillCard(context, drill)).toList(),
      ],
    );
  }

  Widget _buildDrillCard(BuildContext context, Map<String, dynamic> drill) {
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
                    drill['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Focus: ${drill['focus']}',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              drill['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sports_handball, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Equipment: ${drill['equipment']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.assignment),
                  label: Text('Assign to Players'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    // TODO: Implement assign functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Player assignment will be implemented soon')),
                    );
                  },
                ),
                Row(
                  children: [
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
          ],
        ),
      ),
    );
  }

  void _showAddDrillDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Spike Drill'),
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