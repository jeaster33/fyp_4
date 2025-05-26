import 'package:flutter/material.dart';
import 'sketch_painter.dart';

class TacticBoardPage extends StatefulWidget {
  @override
  _TacticBoardPageState createState() => _TacticBoardPageState();
}

class _TacticBoardPageState extends State<TacticBoardPage> {
  // Initial positions of the players on the tactic board.
  final List<Offset> playerPositions = [
    Offset(100, 300), // Team A Player 1
    Offset(200, 300), // Team A Player 2
    Offset(150, 300), // Team A Player 3
    Offset(100, 600), // Team B Player 1
    Offset(200, 600), // Team B Player 2
    Offset(150, 600), // Team B Player 3
  ];

  // Player names list
  List<String> playerNames = [
    'P1', // Team A Player 1
    'P2', // Team A Player 2
    'P3', // Team A Player 3
    'P1', // Team B Player 1
    'P2', // Team B Player 2
    'P3', // Team B Player 3
  ];

  bool isSketchMode = false; // Indicates if sketch mode is enabled or disabled.
  List<Offset> drawingPoints = []; // List of points for freehand drawing.
  final Offset lineBreak = Offset(-1, -1); // Special value to separate different lines in freehand drawing.

  // Color for the sketch button, changes based on sketch mode state.
  Color sketchButtonColor = Colors.grey[300]!;

  // Resets the player positions to their initial values.
  void resetPositions() {
    setState(() {
      playerPositions[0] = Offset(100, 300);
      playerPositions[1] = Offset(200, 300);
      playerPositions[2] = Offset(150, 300);
      playerPositions[3] = Offset(100, 600);
      playerPositions[4] = Offset(200, 600);
      playerPositions[5] = Offset(150, 600);
    });
  }

  // Toggles sketch mode on or off and updates the button color.
  void toggleSketchMode() {
    setState(() {
      isSketchMode = !isSketchMode; // Flip the sketch mode flag.
      sketchButtonColor = isSketchMode ? Colors.orange : Colors.grey[300]!; // Change button color.
    });
  }

  // Clears all freehand drawing points.
  void clearDrawing() {
    setState(() {
      drawingPoints.clear(); // Remove all points from the drawing list.
    });
  }

  // Show dialog to edit player name
  void editPlayerName(int index) {
    final TextEditingController nameController = TextEditingController(text: playerNames[index]);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Edit Player Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Player Name',
              hintText: 'Enter player name',
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  playerNames[index] = nameController.text.isNotEmpty ? nameController.text : playerNames[index];
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Builds a circular player widget with a specific index.
  Widget buildPlayer(int index) {
    return GestureDetector(
      onTap: () {
        // Only allow editing names when sketch mode is off
        if (!isSketchMode) {
          editPlayerName(index);
        }
      },
      child: Container(
        width: 50, // Width of the player widget.
        height: 50, // Height of the player widget.
        decoration: BoxDecoration(
          shape: BoxShape.circle, // Circular shape for the player.
          color: index < 3 ? Colors.blue : Colors.red, // Blue for Team A, Red for Team B.
        ),
        child: Center(
          child: Text(
            playerNames[index], // Use the custom player name
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: playerNames[index].length > 3 ? 12 : 14, // Smaller font for longer names
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background representing the Sepak Takraw court.
        Container(
          color: Colors.brown[300], // Light brown background for the court.
          child: Center(
            child: Container(
              height: 600, // Height of the court.
              width: 300, // Width of the court.
              decoration: BoxDecoration(
                color: Colors.brown[500], // Darker brown for the main court area.
                border: Border.all(color: Colors.white, width: 2), // White border around the court.
              ),
              child: Stack(
                children: [
                  // Court division line
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 300,
                    child: Container(
                      height: 2,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Service circle - Team A (top half)
                  Positioned(
                    left: 150 - 15,
                    top: 150 - 15,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  
                  // Service circle - Team B (bottom half)
                  Positioned(
                    left: 150 - 15,
                    top: 450 - 15,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Players on the court.
        for (int i = 0; i < playerPositions.length; i++)
          Positioned(
            left: playerPositions[i].dx - 25,
            top: playerPositions[i].dy - 25,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  playerPositions[i] = playerPositions[i] + details.delta;
                });
              },
              child: buildPlayer(i),
            ),
          ),

        // Canvas for freehand drawing when sketch mode is enabled.
        if (isSketchMode)
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                drawingPoints.add(details.localPosition); // Add points as the user draws.
              });
            },
            onPanEnd: (details) {
              drawingPoints.add(lineBreak); // Add a line break at the end of the drawing gesture.
            },
            child: CustomPaint(
              painter: SketchPainter(drawingPoints, lineBreak), // Custom painter for freehand drawing.
              size: Size.infinite, // Fill the entire available space.
            ),
          ),

        // Buttons for user interactions.
        Positioned(
          bottom: 20, // Position from the bottom of the screen.
          left: 20, // Position from the left of the screen.
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.create), // Icon for sketch mode toggle.
                color: sketchButtonColor, // Dynamic color based on sketch mode state.
                onPressed: toggleSketchMode, // Toggles sketch mode.
              ),
              IconButton(
                icon: Icon(Icons.clear), // Icon for clearing the drawing.
                onPressed: clearDrawing, // Clears all drawings.
              ),
              IconButton(
                icon: Icon(Icons.refresh), // Icon for resetting player positions.
                onPressed: resetPositions, // Resets player positions.
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Main entry point app widget
class TakrawTacticBoardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tactic Board'),
        backgroundColor: Colors.orange,
      ),
      body: TacticBoardPage(),
    );
  }
}