import 'package:flutter/material.dart';
import 'gameboard.dart';

class ScoreboardPage extends StatefulWidget {
  @override
  _ScoreboardPageState createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  int teamAScore = 0; 
  int teamBScore = 0;
  int teamASets = 0;
  int teamBSets = 0;
  int currentSet = 1;
  final int pointsToWinSet = 21;
  final int setsToWinMatch = 2;
  
  String teamAName = "Team A";
  String teamBName = "Team B";
  String? servingTeam;
  bool matchOver = false;
  String? winningTeam;
  bool isDeuce = false;
  
  List<Map<String, dynamic>> setScores = [];
  List<Map<String, dynamic>> scoreHistory = [];

  void updateScore(String team) {
    if (servingTeam == null || matchOver) return;

    setState(() {
      scoreHistory.add({'A': teamAScore, 'B': teamBScore, 'servingTeam': servingTeam});
      
      if (team == 'A') {
        teamAScore += 1;
      } else {
        teamBScore += 1;
      }
      
      servingTeam = servingTeam == 'A' ? 'B' : 'A';
      
      if (teamAScore >= 20 && teamBScore >= 20) {
        isDeuce = true;
      }
      
      if (teamAScore >= pointsToWinSet && (!isDeuce || teamAScore - teamBScore >= 2)) {
        _completeSet('A');
      } else if (teamBScore >= pointsToWinSet && (!isDeuce || teamBScore - teamAScore >= 2)) {
        _completeSet('B');
      }
    });
  }

  void _completeSet(String winningTeamOfSet) {
    setScores.add({
      'set': currentSet,
      'teamAScore': teamAScore,
      'teamBScore': teamBScore,
      'winner': winningTeamOfSet
    });
    
    if (winningTeamOfSet == 'A') {
      teamASets++;
    } else {
      teamBSets++;
    }
    
    if (teamASets >= setsToWinMatch) {
      matchOver = true;
      winningTeam = 'A';
    } else if (teamBSets >= setsToWinMatch) {
      matchOver = true;
      winningTeam = 'B';
    } else {
      currentSet++;
      teamAScore = 0;
      teamBScore = 0;
      scoreHistory.clear();
      isDeuce = false;
    }
  }

  void undoLastScore() {
    setState(() {
      if (scoreHistory.isNotEmpty) {
        Map<String, dynamic> lastScores = scoreHistory.removeLast();
        teamAScore = lastScores['A'];
        teamBScore = lastScores['B'];
        servingTeam = lastScores['servingTeam'];
        isDeuce = teamAScore >= 20 && teamBScore >= 20;
      }
    });
  }

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

  void startServing(String team) {
    setState(() {
      servingTeam = team;
    });
  }

  void editTeamName(String team) {
    TextEditingController nameController = TextEditingController(
      text: team == 'A' ? teamAName : teamBName,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit ${team == 'A' ? "Team A" : "Team B"} Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Enter new name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Sets display and match info
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Set $currentSet',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Sets: $teamAName ($teamASets) - ($teamBSets) $teamBName',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    if (isDeuce && !matchOver) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: Text(
                          'DEUCE - Win by 2 points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                    if (matchOver) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          '🏆 ${winningTeam == 'A' ? teamAName : teamBName} WINS!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Score display for current set
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildScoreColumn(teamAName, teamAScore, 'A'),
                  buildScoreColumn(teamBName, teamBScore, 'B'),
                ],
              ),
              
              SizedBox(height: 30),
              
              // Set history display
              if (setScores.isNotEmpty) ...[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Previous Sets',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...setScores.map((set) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Set ${set['set']}: $teamAName ${set['teamAScore']} - ${set['teamBScore']} $teamBName',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      )),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],
              
              // Action buttons with oval shape
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: undoLastScore,
                          child: Text('Undo Point', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // More oval
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: resetMatch,
                          child: Text('New Match', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // More oval
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TakrawTacticBoardApp()),
                        );
                      },
                      child: Text('Go to Game Board', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // More oval
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Add extra bottom spacing for scroll
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildScoreColumn(String teamName, int score, String team) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => editTeamName(team),
          child: Column(
            children: [
              Text(
                teamName,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'Sets: ${team == 'A' ? teamASets : teamBSets}',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        if (servingTeam == null && !matchOver)
          ElevatedButton(
            onPressed: () => startServing(team),
            child: Text('Start Serving', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), // More oval
              ),
              elevation: 3,
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
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: matchOver ? Colors.grey.shade200 : Colors.orange.withOpacity(0.2),
                    border: Border.all(
                      color: matchOver ? Colors.grey.shade300 : Colors.orange.withOpacity(0.6),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 52, 
                      fontWeight: FontWeight.bold,
                      color: matchOver ? Colors.grey.shade600 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
              if (servingTeam == team && !matchOver)
                Positioned(
                  bottom: -20,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sports_volleyball,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class SepakTakrawApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sepak Takraw Scoreboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ScoreboardPage(),
    );
  }
}