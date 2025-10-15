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

// Field mapping from snake_case to camelCase
const fieldMappings = {
  // Leagues table
  'logo_url': 'logoUrl',
  'is_active': 'isActive',
  'created_at': 'createdAt',
  'updated_at': 'updatedAt',
  
  // Teams table
  'league_id': 'leagueId',
  'logo_url': 'logoUrl',
  'created_at': 'createdAt',
  'updated_at': 'updatedAt',
  
  // Venues table
  'home_team_id': 'homeTeamId',
  'created_at': 'createdAt',
  'updated_at': 'updatedAt',
  
  // Games table
  'home_team_id': 'homeTeamId',
  'away_team_id': 'awayTeamId',
  'league_id': 'leagueId',
  'game_date': 'gameDate',
  'game_time': 'gameTime',
  'venue_id': 'venueId',
  'home_score': 'homeScore',
  'away_score': 'awayScore',
  'is_live': 'isLive',
  'is_completed': 'isCompleted',
  'box_score': 'boxScore',
  'created_at': 'createdAt',
  'updated_at': 'updatedAt',
  
  // Players table
  'team_id': 'teamId',
  'display_name': 'displayName',
  'first_name': 'firstName',
  'last_name': 'lastName',
  'jersey_number': 'jerseyNumber',
  'primary_position': 'primaryPosition',
  'secondary_position': 'secondaryPosition',
  'height_inches': 'heightInches',
  'weight_lbs': 'weightLbs',
  'photo_url': 'photoUrl',
  'injury_status': 'injuryStatus',
  'draft_year': 'draftYear',
  'draft_pick_overall': 'draftPickOverall',
  'created_at': 'createdAt',
  'updated_at': 'updatedAt',
  
  // Data freshness table
  'league_id': 'leagueId',
  'last_updated': 'lastUpdated',
  'last_successful_fetch': 'lastSuccessfulFetch',
  'fetch_attempts': 'fetchAttempts',
  'last_error': 'lastError'
};

const migrateToCamelCase = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      console.log('Starting migration to camelCase...');

      // Helper function to rename columns in a table
      const renameTableColumns = (tableName, mappings) => {
        return new Promise((resolve, reject) => {
          // Get current table schema
          db.all(`PRAGMA table_info(${tableName})`, (err, columns) => {
            if (err) {
              console.error(`Error getting schema for ${tableName}:`, err);
              reject(err);
              return;
            }

            // Create new table with camelCase columns
            const newColumns = columns.map(col => {
              const newName = mappings[col.name] || col.name;
              return `${newName} ${col.type}${col.notnull ? ' NOT NULL' : ''}${col.pk ? ' PRIMARY KEY' : ''}${col.dflt_value ? ` DEFAULT ${col.dflt_value}` : ''}`;
            }).join(', ');

            // Add foreign key constraints
            let foreignKeys = '';
            if (tableName === 'teams') {
              foreignKeys = ', FOREIGN KEY (leagueId) REFERENCES leagues (id)';
            } else if (tableName === 'venues') {
              foreignKeys = ', FOREIGN KEY (homeTeamId) REFERENCES teams (id)';
            } else if (tableName === 'games') {
              foreignKeys = ', FOREIGN KEY (homeTeamId) REFERENCES teams (id), FOREIGN KEY (awayTeamId) REFERENCES teams (id), FOREIGN KEY (leagueId) REFERENCES leagues (id), FOREIGN KEY (venueId) REFERENCES venues (id)';
            } else if (tableName === 'players') {
              foreignKeys = ', FOREIGN KEY (teamId) REFERENCES teams (id) ON DELETE SET NULL';
            } else if (tableName === 'data_freshness') {
              foreignKeys = ', FOREIGN KEY (leagueId) REFERENCES leagues (id)';
            }

            const createNewTable = `
              CREATE TABLE ${tableName}_new (
                ${newColumns}${foreignKeys}
              )
            `;

            db.run(createNewTable, (err) => {
              if (err) {
                console.error(`Error creating new ${tableName} table:`, err);
                reject(err);
                return;
              }

              // Copy data from old table to new table
              const oldColumns = columns.map(col => col.name).join(', ');
              const newColumnNames = columns.map(col => mappings[col.name] || col.name).join(', ');
              
              const copyData = `
                INSERT INTO ${tableName}_new (${newColumnNames})
                SELECT ${oldColumns} FROM ${tableName}
              `;

              db.run(copyData, (err) => {
                if (err) {
                  console.error(`Error copying data for ${tableName}:`, err);
                  reject(err);
                  return;
                }

                // Drop old table and rename new table
                db.run(`DROP TABLE ${tableName}`, (err) => {
                  if (err) {
                    console.error(`Error dropping old ${tableName} table:`, err);
                    reject(err);
                    return;
                  }

                  db.run(`ALTER TABLE ${tableName}_new RENAME TO ${tableName}`, (err) => {
                    if (err) {
                      console.error(`Error renaming new ${tableName} table:`, err);
                      reject(err);
                      return;
                    }

                    console.log(`✓ Migrated ${tableName} table to camelCase`);
                    resolve();
                  });
                });
              });
            });
          });
        });
      };

      // Migrate each table
      const migrateTables = async () => {
        try {
          // Migrate leagues table
          await renameTableColumns('leagues', {
            'logo_url': 'logoUrl',
            'is_active': 'isActive',
            'created_at': 'createdAt',
            'updated_at': 'updatedAt'
          });

          // Migrate teams table
          await renameTableColumns('teams', {
            'league_id': 'leagueId',
            'logo_url': 'logoUrl',
            'created_at': 'createdAt',
            'updated_at': 'updatedAt'
          });

          // Migrate venues table
          await renameTableColumns('venues', {
            'home_team_id': 'homeTeamId',
            'created_at': 'createdAt',
            'updated_at': 'updatedAt'
          });

          // Migrate games table
          await renameTableColumns('games', {
            'home_team_id': 'homeTeamId',
            'away_team_id': 'awayTeamId',
            'league_id': 'leagueId',
            'game_date': 'gameDate',
            'game_time': 'gameTime',
            'venue_id': 'venueId',
            'home_score': 'homeScore',
            'away_score': 'awayScore',
            'is_live': 'isLive',
            'is_completed': 'isCompleted',
            'box_score': 'boxScore',
            'created_at': 'createdAt',
            'updated_at': 'updatedAt'
          });

          // Migrate players table
          await renameTableColumns('players', {
            'team_id': 'teamId',
            'display_name': 'displayName',
            'first_name': 'firstName',
            'last_name': 'lastName',
            'jersey_number': 'jerseyNumber',
            'primary_position': 'primaryPosition',
            'secondary_position': 'secondaryPosition',
            'height_inches': 'heightInches',
            'weight_lbs': 'weightLbs',
            'photo_url': 'photoUrl',
            'injury_status': 'injuryStatus',
            'draft_year': 'draftYear',
            'draft_pick_overall': 'draftPickOverall',
            'created_at': 'createdAt',
            'updated_at': 'updatedAt'
          });

          // Migrate data_freshness table
          await renameTableColumns('data_freshness', {
            'league_id': 'leagueId',
            'last_updated': 'lastUpdated',
            'last_successful_fetch': 'lastSuccessfulFetch',
            'fetch_attempts': 'fetchAttempts',
            'last_error': 'lastError'
          });

          // Recreate indexes with camelCase column names
          console.log('Recreating indexes...');
          
          const indexes = [
            'CREATE INDEX IF NOT EXISTS idxGamesLeagueSeason ON games (leagueId, season)',
            'CREATE INDEX IF NOT EXISTS idxGamesDate ON games (gameDate)',
            'CREATE INDEX IF NOT EXISTS idxGamesHomeTeam ON games (homeTeamId)',
            'CREATE INDEX IF NOT EXISTS idxGamesAwayTeam ON games (awayTeamId)',
            'CREATE INDEX IF NOT EXISTS idxGamesVenue ON games (venueId)',
            'CREATE INDEX IF NOT EXISTS idxTeamsLeague ON teams (leagueId)',
            'CREATE INDEX IF NOT EXISTS idxTeamsConference ON teams (conference)',
            'CREATE INDEX IF NOT EXISTS idxVenuesHomeTeam ON venues (homeTeamId)',
            'CREATE INDEX IF NOT EXISTS idxPlayersTeam ON players (teamId)',
            'CREATE INDEX IF NOT EXISTS idxPlayersDisplayName ON players (displayName)',
            'CREATE INDEX IF NOT EXISTS idxPlayersPosition ON players (primaryPosition)',
            'CREATE INDEX IF NOT EXISTS idxPlayersActive ON players (active)'
          ];

          for (const indexSQL of indexes) {
            db.run(indexSQL, (err) => {
              if (err) {
                console.error('Error creating index:', err);
              }
            });
          }

          console.log('✓ Migration to camelCase completed successfully!');
          resolve();

        } catch (error) {
          console.error('Migration failed:', error);
          reject(error);
        }
      };

      migrateTables();
    });
  });
};

// Run migration
migrateToCamelCase()
  .then(() => {
    console.log('Migration completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Migration failed:', error);
    process.exit(1);
  });

module.exports = { migrateToCamelCase };
