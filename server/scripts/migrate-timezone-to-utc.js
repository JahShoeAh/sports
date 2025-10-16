const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database path
const dbPath = path.join(__dirname, '../data/sports.db');

// Create database connection
const db = new sqlite3.Database(dbPath);

console.log('Starting timezone migration to UTC...');

// Function to convert ET time to UTC
function convertETToUTC(dateString, timeString) {
  // Create a date in Eastern Time
  const etDate = new Date(`${dateString}T${timeString}`);
  
  // Convert to UTC by adding the timezone offset
  // Eastern Time is UTC-5 (EST) or UTC-4 (EDT)
  // We'll use the current timezone offset to determine if it's EST or EDT
  const now = new Date();
  const isEDT = now.getTimezoneOffset() < 300; // EDT if offset < 5 hours
  const utcOffset = isEDT ? 4 : 5; // EDT is UTC-4, EST is UTC-5
  
  const utcDate = new Date(etDate.getTime() + (utcOffset * 60 * 60 * 1000));
  return utcDate;
}

// Function to add Z suffix to UTC time
function addZToUTCTime(dateString, timeString) {
  return new Date(`${dateString}T${timeString}Z`).toISOString();
}

// Function to extract date from game ID
function extractDateFromGameId(gameId) {
  // Game ID format: NBA_YYYYMMDD_TEAM1_TEAM2
  const match = gameId.match(/NBA_(\d{8})_/);
  if (match) {
    const dateStr = match[1];
    return `${dateStr.slice(0,4)}-${dateStr.slice(4,6)}-${dateStr.slice(6,8)}`;
  }
  return null;
}

// Function to create new game ID with updated date
function createNewGameId(oldGameId, newDate) {
  // Convert YYYY-MM-DD to YYYYMMDD
  const dateStr = newDate.replace(/-/g, '');
  return oldGameId.replace(/NBA_\d{8}_/, `NBA_${dateStr}_`);
}

async function migrateTimezone() {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // First, let's see what we're working with
      console.log('Analyzing current data...');
      
      db.all(`
        SELECT id, gameDate, gameTime, season 
        FROM games 
        WHERE leagueId = 'NBA' 
        ORDER BY season, gameDate
        LIMIT 10
      `, (err, rows) => {
        if (err) {
          console.error('Error querying games:', err);
          reject(err);
          return;
        }
        
        console.log('Sample data before migration:');
        rows.forEach(row => {
          console.log(`  ${row.id} | ${row.gameDate} | ${row.gameTime} | ${row.season}`);
        });
        
        // Start migration
        console.log('\nStarting migration...');
        
        // Get all NBA games
        db.all(`
          SELECT id, gameDate, gameTime, season 
          FROM games 
          WHERE leagueId = 'NBA'
        `, (err, games) => {
          if (err) {
            console.error('Error fetching games:', err);
            reject(err);
            return;
          }
          
          console.log(`Found ${games.length} games to migrate`);
          
          let processed = 0;
          let updated = 0;
          let errors = 0;
          
          // Process each game
          games.forEach((game, index) => {
            let newGameTime;
            let newGameId = game.id;
            
            try {
              if (game.season === '2024-25 Regular') {
                // Convert ET to UTC
                const utcDate = convertETToUTC(game.gameDate, game.gameTime);
                newGameTime = utcDate.toISOString();
                
                // Check if date changed
                const utcDateString = utcDate.toISOString().split('T')[0];
                if (utcDateString !== game.gameDate) {
                  newGameId = createNewGameId(game.id, utcDateString);
                  console.log(`  Date changed: ${game.id} -> ${newGameId} (${game.gameDate} -> ${utcDateString})`);
                }
              } else {
                // Add Z suffix to existing UTC times
                newGameTime = addZToUTCTime(game.gameDate, game.gameTime);
              }
              
              // Update the game
              const updateQuery = `
                UPDATE games 
                SET gameTime = ?, id = ?
                WHERE id = ?
              `;
              
              db.run(updateQuery, [newGameTime, newGameId, game.id], function(err) {
                if (err) {
                  console.error(`Error updating game ${game.id}:`, err);
                  errors++;
                } else {
                  updated++;
                  if (newGameId !== game.id) {
                    console.log(`  Updated game ID: ${game.id} -> ${newGameId}`);
                  }
                }
                
                processed++;
                
                if (processed === games.length) {
                  console.log(`\nMigration completed:`);
                  console.log(`  Processed: ${processed} games`);
                  console.log(`  Updated: ${updated} games`);
                  console.log(`  Errors: ${errors} games`);
                  
                  // Now remove the gameDate column
                  console.log('\nRemoving gameDate column...');
                  db.run(`ALTER TABLE games DROP COLUMN gameDate`, (err) => {
                    if (err) {
                      console.error('Error removing gameDate column:', err);
                      reject(err);
                    } else {
                      console.log('Successfully removed gameDate column');
                      
                      // Show sample data after migration
                      db.all(`
                        SELECT id, gameTime, season 
                        FROM games 
                        WHERE leagueId = 'NBA' 
                        ORDER BY season, gameTime
                        LIMIT 10
                      `, (err, rows) => {
                        if (err) {
                          console.error('Error querying after migration:', err);
                          reject(err);
                        } else {
                          console.log('\nSample data after migration:');
                          rows.forEach(row => {
                            console.log(`  ${row.id} | ${row.gameTime} | ${row.season}`);
                          });
                          resolve();
                        }
                      });
                    }
                  });
                }
              });
            } catch (error) {
              console.error(`Error processing game ${game.id}:`, error);
              errors++;
              processed++;
              
              if (processed === games.length) {
                console.log(`\nMigration completed with errors:`);
                console.log(`  Processed: ${processed} games`);
                console.log(`  Updated: ${updated} games`);
                console.log(`  Errors: ${errors} games`);
                resolve();
              }
            }
          });
        });
      });
    });
  });
}

// Run the migration
migrateTimezone()
  .then(() => {
    console.log('\nMigration completed successfully!');
    db.close();
  })
  .catch((error) => {
    console.error('Migration failed:', error);
    db.close();
    process.exit(1);
  });
