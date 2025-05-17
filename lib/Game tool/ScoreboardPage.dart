import 'package:flutter/material.dart';
import 'gameboard.dart';

// Stateful widget for the scoreboard functionality.
class ScoreboardPage extends StatefulWidget {
  @override
  _ScoreboardPageState createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  int teamAScore = 0; // Score for Team A.
  int teamBScore = 0; // Score for Team B.
  String teamAName = "Team A"; // Name for Team A.
  String teamBName = "Team B"; // Name for Team B.
  String? servingTeam; // Indicates the serving team ('A' or 'B').
  List<Map<String, dynamic>> scoreHistory = []; // Keeps track of score history for undo functionality.

  // Updates the score for the given team.
  void updateScore(String team) {
    if (servingTeam == null) return; // If no serving team is selected, do nothing.

    setState(() {
      // Save the current scores and serving team to the history list.
      scoreHistory.add({'A': teamAScore, 'B': teamBScore, 'servingTeam': servingTeam});
      if (team == 'A') {
        teamAScore += 1; // Increment Team A's score.
      } else {
        teamBScore += 1; // Increment Team B's score.
      }
      // Toggle the serving team after a score update.
      servingTeam = servingTeam == 'A' ? 'B' : 'A';
    });
  }

  // Undo the last score update.
  void undoLastScore() {
    setState(() {
      if (scoreHistory.isNotEmpty) {
        // Restore the last saved scores and serving team.
        Map<String, dynamic> lastScores = scoreHistory.removeLast();
        teamAScore = lastScores['A'];
        teamBScore = lastScores['B'];
        servingTeam = lastScores['servingTeam'];
      }
    });
  }

  // Sets the serving team at the start of the game.
  void startServing(String team) {
    setState(() {
      servingTeam = team;
    });
  }

  // Opens a dialog to edit the team name.
  void editTeamName(String team) {
    TextEditingController nameController = TextEditingController(
      text: team == 'A' ? teamAName : teamBName, // Pre-fill with the current team name.
    );

    // Display a dialog for editing the team name.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${team == 'A' ? "Team A" : "Team B"} Name'), // Dialog title.
          content: TextField(
            controller: nameController, // Input field for the new name.
            decoration: InputDecoration(labelText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without saving changes.
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Save the new name based on the selected team.
                  if (team == 'A') {
                    teamAName = nameController.text;
                  } else {
                    teamBName = nameController.text;
                  }
                });
                Navigator.of(context).pop(); // Close the dialog after saving changes.
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute elements evenly.
      children: [
        // Display scores for both teams.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Space between columns.
          children: [
            buildScoreColumn(teamAName, teamAScore, 'A'), // Team A's score column.
            buildScoreColumn(teamBName, teamBScore, 'B'), // Team B's score column.
          ],
        ),
        ElevatedButton(
          onPressed: undoLastScore, // Undo the last score update.
          child: Text('Undo'),
        ),
        ElevatedButton(
          onPressed: () {
            // Navigate to the tactic board screen.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TakrawTacticBoardApp()),
            );
          },
          child: Text('Go to Game Board'),
        ),
      ],
    );
  }

  // Builds the score display for a team, including the team name and score.
  Widget buildScoreColumn(String teamName, int score, String team) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => editTeamName(team), // Edit team name on tap.
          child: Text(
            teamName, // Display the team name.
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (servingTeam == null)
          ElevatedButton(
            onPressed: () => startServing(team), // Start serving for the selected team.
            child: Text('Start Serving'),
          )
        else
          Stack(
            alignment: Alignment.center, // Center the score and serving icon.
            clipBehavior: Clip.none, // Ensure the icon is not clipped.
            children: [
              GestureDetector(
                onTap: () => updateScore(team), // Update the score on tap.
                child: Text(
                  '$score', // Display the team's current score.
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
              if (servingTeam == team)
                Positioned(
                  bottom: -15, // Position the serving icon below the score.
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Prevent overlap with the score.
                    child: Icon(
                      Icons.sports_volleyball, // Serving icon.
                      size: 24,
                      color: Colors.orange, // Icon color.
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// Main app widget for the Sepak Takraw Scoreboard.
class SepakTakrawApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sepak Takraw Scoreboard'),
        backgroundColor: Colors.orange,
      ),
      body: ScoreboardPage(),
    );
  }
}