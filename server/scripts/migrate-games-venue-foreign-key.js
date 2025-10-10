const sqlite3 = require('sqlite3').verbose();
const config = require('../config');
const path = require('path');
const fs = require('fs');

// Ensure data directory exists
const dataDir = path.dirname(config.dbPath);
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// Create database connection
const db = new sqlite3.Database(config.dbPath);

const migrateGamesVenueForeignKey = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      console.log('Starting games venue foreign key migration...');

      // First, let's check if venues table exists and has data
      db.get(`SELECT COUNT(*) as count FROM venues`, (err, row) => {
        if (err) {
          console.error('Error checking venues table:', err);
          reject(err);
          return;
        }

        console.log(`Found ${row.count} venues in database`);

        if (row.count === 0) {
          console.log('No venues found. Please populate venues table first.');
          reject(new Error('No venues found in database'));
          return;
        }

        // Create a mapping of venue names to venue IDs
        db.all(`SELECT id, name FROM venues`, (err, venues) => {
          if (err) {
            console.error('Error fetching venues:', err);
            reject(err);
            return;
          }

          const venueNameToId = {};
          venues.forEach(venue => {
            venueNameToId[venue.name] = venue.id;
          });

          console.log(`Created venue mapping for ${Object.keys(venueNameToId).length} venues`);

          // Get all games with venue data
          db.all(`SELECT id, venue FROM games WHERE venue IS NOT NULL AND venue != ''`, (err, games) => {
            if (err) {
              console.error('Error fetching games:', err);
              reject(err);
              return;
            }

            console.log(`Found ${games.length} games with venue data`);

            // Create new games table with venue_id foreign key
            db.run(`
              CREATE TABLE IF NOT EXISTS games_new (
                id TEXT PRIMARY KEY,
                home_team_id TEXT NOT NULL,
                away_team_id TEXT NOT NULL,
                league_id TEXT NOT NULL,
                season TEXT NOT NULL,
                week INTEGER,
                game_date DATETIME NOT NULL,
                game_time DATETIME NOT NULL,
                venue_id TEXT,
                home_score INTEGER,
                away_score INTEGER,
                quarter INTEGER,
                is_live BOOLEAN DEFAULT 0,
                is_completed BOOLEAN DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (home_team_id) REFERENCES teams (id),
                FOREIGN KEY (away_team_id) REFERENCES teams (id),
                FOREIGN KEY (league_id) REFERENCES leagues (id),
                FOREIGN KEY (venue_id) REFERENCES venues (id)
              )
            `, (err) => {
              if (err) {
                console.error('Error creating new games table:', err);
                reject(err);
                return;
              }

              console.log('✓ Created new games table with venue_id foreign key');

              // Process each game and map venue data
              let processedGames = 0;
              let matchedVenues = 0;
              let unmatchedVenues = 0;

              const processGame = (game) => {
                return new Promise((resolveGame, rejectGame) => {
                  let venueId = null;

                  try {
                    // Try to parse venue JSON
                    const venueData = JSON.parse(game.venue);
                    const venueName = venueData.name;

                    if (venueNameToId[venueName]) {
                      venueId = venueNameToId[venueName];
                      matchedVenues++;
                    } else {
                      console.log(`⚠️  No matching venue found for: ${venueName}`);
                      unmatchedVenues++;
                    }
                  } catch (parseError) {
                    console.log(`⚠️  Could not parse venue JSON for game ${game.id}: ${game.venue}`);
                    unmatchedVenues++;
                  }

                  // Copy game data to new table
                  db.run(`
                    INSERT INTO games_new (
                      id, home_team_id, away_team_id, league_id, season, week,
                      game_date, game_time, venue_id, home_score, away_score,
                      quarter, is_live, is_completed, created_at, updated_at
                    )
                    SELECT 
                      id, home_team_id, away_team_id, league_id, season, week,
                      game_date, game_time, ?, home_score, away_score,
                      quarter, is_live, is_completed, created_at, updated_at
                    FROM games
                    WHERE id = ?
                  `, [venueId, game.id], (err) => {
                    if (err) {
                      console.error(`Error copying game ${game.id}:`, err);
                      rejectGame(err);
                    } else {
                      processedGames++;
                      console.log(`✓ Processed game ${game.id} (${processedGames}/${games.length})`);
                      resolveGame();
                    }
                  });
                });
              };

              // Process all games
              Promise.all(games.map(processGame))
                .then(() => {
                  console.log(`\n📊 Migration Summary:`);
                  console.log(`- Processed ${processedGames} games`);
                  console.log(`- Matched ${matchedVenues} venues`);
                  console.log(`- Unmatched ${unmatchedVenues} venues`);

                  // Drop old games table and rename new one
                  db.run(`DROP TABLE games`, (err) => {
                    if (err) {
                      console.error('Error dropping old games table:', err);
                      reject(err);
                      return;
                    }

                    console.log('✓ Dropped old games table');

                    db.run(`ALTER TABLE games_new RENAME TO games`, (err) => {
                      if (err) {
                        console.error('Error renaming new games table:', err);
                        reject(err);
                        return;
                      }

                      console.log('✓ Renamed games_new to games');

                      // Recreate indexes
                      const indexes = [
                        'CREATE INDEX IF NOT EXISTS idx_games_league_season ON games (league_id, season)',
                        'CREATE INDEX IF NOT EXISTS idx_games_date ON games (game_date)',
                        'CREATE INDEX IF NOT EXISTS idx_games_home_team ON games (home_team_id)',
                        'CREATE INDEX IF NOT EXISTS idx_games_away_team ON games (away_team_id)',
                        'CREATE INDEX IF NOT EXISTS idx_games_venue ON games (venue_id)'
                      ];

                      let completedIndexes = 0;
                      indexes.forEach(indexQuery => {
                        db.run(indexQuery, (err) => {
                          if (err) {
                            console.error(`Error creating index:`, err);
                          } else {
                            console.log(`✓ Created index`);
                          }
                          completedIndexes++;
                          if (completedIndexes === indexes.length) {
                            console.log('✓ All indexes created successfully');
                            console.log('🎉 Games venue foreign key migration completed successfully!');
                            resolve();
                          }
                        });
                      });
                    });
                  });
                })
                .catch((error) => {
                  console.error('Error processing games:', error);
                  reject(error);
                });
            });
          });
        });
      });
    });
  });
};

// Run migration if called directly
if (require.main === module) {
  migrateGamesVenueForeignKey()
    .then(() => {
      console.log('Migration completed successfully');
      db.close();
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration failed:', error);
      db.close();
      process.exit(1);
    });
}

module.exports = { migrateGamesVenueForeignKey };
