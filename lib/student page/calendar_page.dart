import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final int firstWeekday = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday;

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Calendar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month and Year Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                ),
                Text(
                  DateFormat.yMMMM().format(_focusedDay),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Weekday Headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((day) => Text(day, style: TextStyle(fontWeight: FontWeight.bold)))
                  .toList(),
            ),
            SizedBox(height: 8),
            // Calendar Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: daysInMonth + firstWeekday,
                itemBuilder: (context, index) {
                  if (index < firstWeekday) {
                    return SizedBox(); // Empty cells for days before the first day of the month
                  }
                  final day = index - firstWeekday + 1;
                  final date = DateTime(_focusedDay.year, _focusedDay.month, day);
                  final isSelected = _selectedDay != null && _selectedDay == date;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = date;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            // Selected Date Display
            Text(
              _selectedDay != null
                  ? 'Selected Date: ${DateFormat.yMMMd().format(_selectedDay!)}'
                  : 'No Date Selected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}