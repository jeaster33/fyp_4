import 'package:flutter/material.dart';
import 'gameboard.dart';

// Stateful widget for the scoreboard functionality.
class ScoreboardPage extends StatefulWidget {
  @override
  _ScoreboardPageState createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  // Points in current set
  int teamAScore = 0; 
  int teamBScore = 0;
  
  // Set tracking
  int teamASets = 0;
  int teamBSets = 0;
  int currentSet = 1;
  final int pointsToWinSet = 21; // Updated to 21 points
  final int setsToWinMatch = 2;
  
  String teamAName = "Team A";
  String teamBName = "Team B";
  String? servingTeam;
  bool matchOver = false;
  String? winningTeam;
  bool isDeuce = false;
  
  // Keep track of sets history
  List<Map<String, dynamic>> setScores = [];
  
  List<Map<String, dynamic>> scoreHistory = []; // For undo functionality within current set

  // Updates the score for the given team.
  void updateScore(String team) {
    if (servingTeam == null || matchOver) return; // If no serving team or match is over, do nothing.

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
      
      // Update deuce status
      if (teamAScore >= 20 && teamBScore >= 20) {
        isDeuce = true;
      }
      
      // Check if a set has been completed
      if (teamAScore >= pointsToWinSet && (!isDeuce || teamAScore - teamBScore >= 2)) {
        _completeSet('A');
      } else if (teamBScore >= pointsToWinSet && (!isDeuce || teamBScore - teamAScore >= 2)) {
        _completeSet('B');
      }
    });
  }

  // Handle end of set
  void _completeSet(String winningTeamOfSet) {
    // Record set result
    setScores.add({
      'set': currentSet,
      'teamAScore': teamAScore,
      'teamBScore': teamBScore,
      'winner': winningTeamOfSet
    });
    
    // Update sets counter
    if (winningTeamOfSet == 'A') {
      teamASets++;
    } else {
      teamBSets++;
    }
    
    // Check if match is over
    if (teamASets >= setsToWinMatch) {
      matchOver = true;
      winningTeam = 'A';
    } else if (teamBSets >= setsToWinMatch) {
      matchOver = true;
      winningTeam = 'B';
    } else {
      // Continue to next set
      currentSet++;
      teamAScore = 0;
      teamBScore = 0;
      scoreHistory.clear();
      isDeuce = false;
    }
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
        
        // Update deuce status after undo
        isDeuce = teamAScore >= 20 && teamBScore >= 20;
      }
    });
  }

  // Reset the entire match
  void resetMatch() {
    setState(() {
      teamAScore = 0;
      teamBScore = 0;
      teamASets = 0;
      teamBSets = 0;
      currentSet = 1;
      servingTeam = null;
      matchOver = false;
      winningTeam = null;
      isDeuce = false;
      scoreHistory.clear();
      setScores.clear();
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
      text: team == 'A' ? teamAName : teamBName,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${team == 'A' ? "Team A" : "Team B"} Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (team == 'A') {
                    teamAName = nameController.text;
                  } else {
                    teamBName = nameController.text;
                  }
                });
                Navigator.of(context).pop();
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Sets display and match info
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Set $currentSet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sets: $teamAName ($teamASets) - ($teamBSets) $teamBName',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              if (isDeuce && !matchOver)
                Container(
                  margin: EdgeInsets.only(top: 12),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber)
                  ),
                  child: Text(
                    'DEUCE - Win by 2 points',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              if (matchOver)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${winningTeam == 'A' ? teamAName : teamBName} wins the match!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Score display for current set
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildScoreColumn(teamAName, teamAScore, 'A'),
            buildScoreColumn(teamBName, teamBScore, 'B'),
          ],
        ),
        
        // REMOVED: Current set target display
        
        // Set history display
        if (setScores.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Previous Sets',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                ...setScores.map((set) => Text(
                      'Set ${set['set']}: $teamAName ${set['teamAScore']} - ${set['teamBScore']} $teamBName',
                      style: TextStyle(fontSize: 14),
                    )),
              ],
            ),
          ),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: undoLastScore,
              child: Text('Undo Point'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: resetMatch,
              child: Text('New Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TakrawTacticBoardApp()),
            );
          },
          child: Text('Go to Game Board'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Builds the score display for a team
  Widget buildScoreColumn(String teamName, int score, String team) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => editTeamName(team),
          child: Column(
            children: [
              Text(
                teamName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Sets: ${team == 'A' ? teamASets : teamBSets}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        if (servingTeam == null && !matchOver)
          ElevatedButton(
            onPressed: () => startServing(team),
            child: Text('Start Serving'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          )
        else
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: matchOver ? null : () => updateScore(team),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: matchOver ? Colors.grey.shade200 : Colors.orange.withOpacity(0.2),
                  ),
                  child: Text(
                    '$score',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (servingTeam == team && !matchOver)
                Positioned(
                  bottom: -15,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Icon(
                      Icons.sports_volleyball,
                      size: 24,
                      color: Colors.orange,
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