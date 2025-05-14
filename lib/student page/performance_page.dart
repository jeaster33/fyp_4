import 'package:flutter/material.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Performance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Subjects:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ListTile(
              title: Text('Mathematics'),
              subtitle: Text('Grade: A'),
            ),
            ListTile(
              title: Text('Science'),
              subtitle: Text('Grade: B+'),
            ),
            ListTile(
              title: Text('History'),
              subtitle: Text('Grade: A-'),
            ),
          ],
        ),
      ),
    );
  }
}