import 'package:flutter/material.dart';
import 'balance_performance.dart';
import 'spike_performance.dart';
import 'stamina_perfomance.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Performance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training Performance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Track your progress across different training types',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 32),
            _buildTrainingTypeCard(
              context,
              'Stamina Training',
              'Track your endurance progress over time',
              Icons.timer,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StaminaPerformancePage()),
              ),
            ),
            SizedBox(height: 16),
            _buildTrainingTypeCard(
              context,
              'Balance Training',
              'Monitor your stability and balance improvements',
              Icons.balance,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BalancePerformancePage()),
              ),
            ),
            SizedBox(height: 16),
            _buildTrainingTypeCard(
              context,
              'Spike Training',
              'Analyze your attack success rate and technique',
              Icons.sports_volleyball,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SpikePerformancePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrainingTypeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 32),
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
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}