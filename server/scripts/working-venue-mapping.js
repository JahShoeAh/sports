const sqlite3 = require('sqlite3').verbose();
const config = require('../config');
const fs = require('fs');
const csv = require('csv-parser');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

const workingVenueMapping = () => {
  return new Promise((resolve, reject) => {
    console.log('Starting working venue mapping...');

    // Create a mapping of CSV venue names to database venue names
    const venueNameMapping = {
      'Delta Center': 'Vivint Arena',
      'Kia Center': 'Amway Center',
      'Rocket Arena': 'Rocket Mortgage FieldHouse',
      'Madison Square Garden (IV)': 'Madison Square Garden',
      'FedEx Forum': 'FedExForum',
      'Frost Bank Center': 'AT&T Center',
      'Mexico City Arena': 'Mexico City Arena', // This might not exist in our database
      'T-Mobile Arena': 'T-Mobile Arena', // This might not exist in our database
      'AccorHotels Arena': 'AccorHotels Arena', // This might not exist in our database
      'Moody Center': 'Moody Center' // This might not exist in our database
    };

    // Function to convert CSV date format to database format
    const convertDate = (csvDate) => {
      // Convert "Tue Oct 22 2024" to "2024-10-22"
      const date = new Date(csvDate);
      return date.toISOString().split('T')[0];
    };

    // First, let's get all venues and teams from the database
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

      // Get all teams
      db.all(`SELECT id, name FROM teams WHERE league_id = 'NBA'`, (err, teams) => {
        if (err) {
          console.error('Error fetching teams:', err);
          reject(err);
          return;
        }

        console.log(`Found ${teams.length} teams in database`);

        // Create a mapping of team names to team IDs
        const teamNameToId = {};
        teams.forEach(team => {
          teamNameToId[team.name] = team.id;
        });

        console.log(`Created mappings for ${Object.keys(venueNameToId).length} venues and ${Object.keys(teamNameToId).length} teams`);

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
        let mappedVenues = 0;
        let unmappedVenues = 0;

        fs.createReadStream(csvPath)
          .pipe(csv())
          .on('data', (row) => {
            csvRowCount++;
            const arena = row['Arena'];
            const date = row['Date'];
            const homeTeam = row['Home/Neutral'];
            const visitorTeam = row['Visitor/Neutral'];

            if (arena && arena.trim()) {
              // Map team names to team IDs
              const homeTeamId = teamNameToId[homeTeam];
              const visitorTeamId = teamNameToId[visitorTeam];

              if (homeTeamId && visitorTeamId) {
                // Convert date format and create game key
                const dbDate = convertDate(date);
                const gameKey = `${dbDate}_${visitorTeamId}_${homeTeamId}`;
                
                // Map the venue name if needed
                const mappedVenueName = venueNameMapping[arena] || arena;
                
                if (venueNameToId[mappedVenueName]) {
                  gameVenueMap[gameKey] = venueNameToId[mappedVenueName];
                  mappedVenues++;
                } else {
                  console.log(`⚠️  No matching venue found for: ${arena} (mapped to: ${mappedVenueName})`);
                  unmappedVenues++;
                }
              } else {
                console.log(`⚠️  No team mapping found for: ${visitorTeam} vs ${homeTeam}`);
              }
            }
          })
          .on('end', () => {
            console.log(`Processed ${csvRowCount} CSV rows`);
            console.log(`Mapped ${mappedVenues} venues, ${unmappedVenues} unmapped`);
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
                      if (updatedGames % 100 === 0) {
                        console.log(`✓ Updated ${updatedGames} games so far...`);
                      }
                    }
                  });
                } else {
                  notFoundGames++;
                  if (notFoundGames <= 10) { // Only show first 10 for brevity
                    console.log(`⚠️  No venue mapping found for game ${game.id}`);
                  }
                }
              });

              // Wait a bit for all updates to complete, then finalize
              setTimeout(() => {
                updateStmt.finalize();
                
                console.log(`\n📊 Working Venue Mapping Summary:`);
                console.log(`- Updated ${updatedGames} games`);
                console.log(`- Not found ${notFoundGames} games`);
                console.log('🎉 Working venue mapping completed successfully!');
                resolve();
              }, 3000);
            });
          })
          .on('error', (error) => {
            console.error('Error reading CSV file:', error);
            reject(error);
          });
      });
    });
  });
};

// Run migration if called directly
if (require.main === module) {
  workingVenueMapping()
    .then(() => {
      console.log('Working venue mapping completed successfully');
      db.close();
      process.exit(0);
    })
    .catch((error) => {
      console.error('Working venue mapping failed:', error);
      db.close();
      process.exit(1);
    });
}

module.exports = { workingVenueMapping };
