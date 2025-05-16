import 'package:flutter/material.dart';

class TrainingWelcomePage extends StatelessWidget {
  final String userName;
  
  const TrainingWelcomePage({
    Key? key, 
    this.userName = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Training Module',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade100,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Training icon
                Icon(
                  Icons.fitness_center,
                  size: 100,
                  color: Colors.green.shade800,
                ),
                
                const SizedBox(height: 32),
                
                // Welcome text
                Text(
                  userName.isNotEmpty 
                      ? 'Hi $userName,' 
                      : 'Hi,',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Main welcome message
                const Text(
                  'Welcome to Training Page',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Coming soon text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'COMING SOON',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Description
                const Text(
                  'Our training module will help coaches create personalized training plans, track player progress, and provide detailed recommendations.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Features coming soon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade300, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow(Icons.assignment, 'Personalized Training Plans'),
                      const SizedBox(height: 16),
                      _buildFeatureRow(Icons.analytics_outlined, 'Progress Tracking'),
                      const SizedBox(height: 16),
                      _buildFeatureRow(Icons.recommend, 'Performance Recommendations'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Notify button
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You\'ll be notified when the Training feature is available!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green.shade700, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Notify Me When Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green.shade700,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}