const sqlite3 = require('sqlite3').verbose();
const config = require('../config');
const fs = require('fs');
const csv = require('csv-parser');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

const debugVenueMapping = () => {
  return new Promise((resolve, reject) => {
    console.log('Starting debug venue mapping...');

    // Get all teams
    db.all(`SELECT id, name FROM teams WHERE league_id = 'NBA'`, (err, teams) => {
      if (err) {
        console.error('Error fetching teams:', err);
        reject(err);
        return;
      }

      // Create a mapping of team names to team IDs
      const teamNameToId = {};
      teams.forEach(team => {
        teamNameToId[team.name] = team.id;
      });

      console.log('Team mappings:');
      Object.entries(teamNameToId).slice(0, 5).forEach(([name, id]) => {
        console.log(`  ${name} -> ${id}`);
      });

      // Get a few sample games from database
      db.all(`SELECT id, game_date, home_team_id, away_team_id FROM games LIMIT 3`, (err, games) => {
        if (err) {
          console.error('Error fetching games:', err);
          reject(err);
          return;
        }

        console.log('\nSample games from database:');
        games.forEach(game => {
          console.log(`  ${game.id}: ${game.game_date}_${game.away_team_id}_${game.home_team_id}`);
        });

        // Read a few rows from CSV
        const csvPath = 'nba regular 2024 2025.csv';
        let csvRowCount = 0;

        fs.createReadStream(csvPath)
          .pipe(csv())
          .on('data', (row) => {
            if (csvRowCount < 3) {
              const arena = row['Arena'];
              const date = row['Date'];
              const homeTeam = row['Home/Neutral'];
              const visitorTeam = row['Visitor/Neutral'];

              console.log(`\nCSV Row ${csvRowCount + 1}:`);
              console.log(`  Date: ${date}`);
              console.log(`  Home: ${homeTeam} -> ${teamNameToId[homeTeam] || 'NOT FOUND'}`);
              console.log(`  Visitor: ${visitorTeam} -> ${teamNameToId[visitorTeam] || 'NOT FOUND'}`);
              console.log(`  Arena: ${arena}`);
              
              if (teamNameToId[homeTeam] && teamNameToId[visitorTeam]) {
                const gameKey = `${date}_${teamNameToId[visitorTeam]}_${teamNameToId[homeTeam]}`;
                console.log(`  Game Key: ${gameKey}`);
              }
            }
            csvRowCount++;
          })
          .on('end', () => {
            console.log(`\nProcessed ${csvRowCount} CSV rows`);
            resolve();
          })
          .on('error', (error) => {
            console.error('Error reading CSV file:', error);
            reject(error);
          });
      });
    });
  });
};

// Run debug if called directly
if (require.main === module) {
  debugVenueMapping()
    .then(() => {
      console.log('Debug completed');
      db.close();
      process.exit(0);
    })
    .catch((error) => {
      console.error('Debug failed:', error);
      db.close();
      process.exit(1);
    });
}

module.exports = { debugVenueMapping };
