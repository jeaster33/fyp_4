import 'package:flutter/material.dart';
import 'balance_performance.dart';
import 'spike_performance.dart';
import 'stamina_perfomance.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('My Performance'),
        backgroundColor: Color(0xFFF59E0B), // CHANGED: Orange theme matching PERFORMANCE card
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏆 Training Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Track your progress across different training types',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            _buildTrainingTypeCard(
              context,
              'Stamina Training',
              'Track your endurance progress over time',
              Icons.timer,
              Color(0xFF3B82F6),
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
              Color(0xFF10B981),
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
              Color(0xFF8B5CF6),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}