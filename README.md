FootballApp
===========

Football Application using Eiffel+AngulasJS

Compile the finalized version using Nino as the target.
The application is running at port 9090.
You can change all the matches and their bets inside the ./www folder.
Currently , the scheme of things is as follows,

-> To add a match
    - Add the match inside ./www/matches/matches.json file and create a new file with match-matchId.json name

  -Whenever a bet is entered, a bet_matchId.json file is created, containing the list of the bets for the match.
  -Whenever a result is entered, 2 files are created, 1 file stores the details of the result and the person that entered the result, 
    and the other file contains the list of points.
    
-> To add a user
    - Add the username and password for the user inside ./www/matches/login.json
    
  Scores are contained inside ./www/matches/leaderboard
