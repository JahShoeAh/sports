const sqlite3 = require('sqlite3').verbose();
const config = require('../config');
const fs = require('fs');
const csv = require('csv-parser');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

const simpleVenueMapping = () => {
  return new Promise((resolve, reject) => {
    console.log('Starting simple venue mapping...');

    // First, let's get all venues from the database
    db.all(`SELECT id, name FROM venues`, (err, venues) => {
      if (err) {
        console.error('Error fetching venues:', err);
        reject(err);
        return;
      }

      console.log(`Found ${venues.length} venues in database`);

      // Create a mapping of venue names to venue IDs
      const venueNameToId = {};
      venues.forEach(venue => {
        venueNameToId[venue.name] = venue.id;
      });

      console.log(`Created venue mapping for ${Object.keys(venueNameToId).length} venues`);

      // Read the CSV file and create a mapping of games to venues
      const gameVenueMap = {};
      const csvPath = 'nba regular 2024 2025.csv';

      if (!fs.existsSync(csvPath)) {
        console.error('CSV file not found:', csvPath);
        reject(new Error('CSV file not found'));
        return;
      }

      console.log('Reading CSV file...');
      let csvRowCount = 0;

      fs.createReadStream(csvPath)
        .pipe(csv())
        .on('data', (row) => {
          csvRowCount++;
          const arena = row['Arena'];
          const date = row['Date'];
          const homeTeam = row['Home/Neutral'];
          const visitorTeam = row['Visitor/Neutral'];

          if (arena && arena.trim()) {
            // Create a game key based on date and teams
            const gameKey = `${date}_${visitorTeam}_${homeTeam}`;
            
            if (venueNameToId[arena]) {
              gameVenueMap[gameKey] = venueNameToId[arena];
            } else {
              console.log(`⚠️  No matching venue found for: ${arena}`);
            }
          }
        })
        .on('end', () => {
          console.log(`Processed ${csvRowCount} CSV rows`);
          console.log(`Created mapping for ${Object.keys(gameVenueMap).length} games`);

          // Now update the games table with venue IDs
          let updatedGames = 0;
          let notFoundGames = 0;

          const updateStmt = db.prepare(`
            UPDATE games 
            SET venue_id = ?
            WHERE game_date = ? AND home_team_id = ? AND away_team_id = ?
          `);

          // Get all games from the database
          db.all(`SELECT id, game_date, home_team_id, away_team_id FROM games`, (err, games) => {
            if (err) {
              console.error('Error fetching games:', err);
              reject(err);
              return;
            }

            console.log(`Found ${games.length} games in database`);

            // For each game, try to find a matching venue
            games.forEach(game => {
              // Create a game key similar to the CSV format
              const gameKey = `${game.game_date}_${game.away_team_id}_${game.home_team_id}`;
              
              if (gameVenueMap[gameKey]) {
                updateStmt.run(gameVenueMap[gameKey], game.game_date, game.home_team_id, game.away_team_id, (err) => {
                  if (err) {
                    console.error(`Error updating game ${game.id}:`, err);
                  } else {
                    updatedGames++;
                    console.log(`✓ Updated game ${game.id} with venue ${gameVenueMap[gameKey]}`);
                  }
                });
              } else {
                notFoundGames++;
                console.log(`⚠️  No venue mapping found for game ${game.id}`);
              }
            });

            // Wait a bit for all updates to complete, then finalize
            setTimeout(() => {
              updateStmt.finalize();
              
              console.log(`\n📊 Venue Mapping Summary:`);
              console.log(`- Updated ${updatedGames} games`);
              console.log(`- Not found ${notFoundGames} games`);
              console.log('🎉 Simple venue mapping completed successfully!');
              resolve();
            }, 2000);
          });
        })
        .on('error', (error) => {
          console.error('Error reading CSV file:', error);
          reject(error);
        });
    });
  });
};

// Run migration if called directly
if (require.main === module) {
  simpleVenueMapping()
    .then(() => {
      console.log('Simple venue mapping completed successfully');
      db.close();
      process.exit(0);
    })
    .catch((error) => {
      console.error('Simple venue mapping failed:', error);
      db.close();
      process.exit(1);
    });
}

module.exports = { simpleVenueMapping };
