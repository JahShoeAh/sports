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

const migrateSchema = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      console.log('Starting database migration...');

      // Add roster_id column to teams table if it doesn't exist
      db.run(`
        ALTER TABLE teams ADD COLUMN roster_id TEXT
      `, (err) => {
        if (err && !err.message.includes('duplicate column name')) {
          console.error('Error adding roster_id to teams:', err);
        } else {
          console.log('✓ Added roster_id column to teams table');
        }
      });

      // Create rosters table if it doesn't exist (must be first due to foreign key)
      db.run(`
        CREATE TABLE IF NOT EXISTS rosters (
          id TEXT PRIMARY KEY,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `, (err) => {
        if (err) {
          console.error('Error creating rosters table:', err);
        } else {
          console.log('✓ Created rosters table');
        }
      });

      // Update venues table structure
      db.run(`
        CREATE TABLE IF NOT EXISTS venues_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          city TEXT,
          state TEXT,
          country TEXT,
          home_team_id TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (home_team_id) REFERENCES teams (id)
        )
      `, (err) => {
        if (err) {
          console.error('Error creating new venues table:', err);
        } else {
          console.log('✓ Created new venues table structure');
        }
      });

      // Copy data from old venues table to new one (if old table exists)
      db.run(`
        INSERT OR IGNORE INTO venues_new (id, name, city, state, country, created_at, updated_at)
        SELECT id, name, city, state, country, created_at, updated_at
        FROM venues
      `, (err) => {
        if (err && !err.message.includes('no such table')) {
          console.error('Error copying venues data:', err);
        } else {
          console.log('✓ Copied venues data to new structure');
        }
      });

      // Drop old venues table and rename new one
      db.run(`DROP TABLE IF EXISTS venues`, (err) => {
        if (err) {
          console.error('Error dropping old venues table:', err);
        } else {
          console.log('✓ Dropped old venues table');
        }
      });

      db.run(`ALTER TABLE venues_new RENAME TO venues`, (err) => {
        if (err) {
          console.error('Error renaming venues table:', err);
        } else {
          console.log('✓ Renamed venues_new to venues');
        }
      });

      // Update games table - remove columns that are no longer needed
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
          venue TEXT NOT NULL,
          home_score INTEGER,
          away_score INTEGER,
          quarter INTEGER,
          is_live BOOLEAN DEFAULT 0,
          is_completed BOOLEAN DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (home_team_id) REFERENCES teams (id),
          FOREIGN KEY (away_team_id) REFERENCES teams (id),
          FOREIGN KEY (league_id) REFERENCES leagues (id)
        )
      `, (err) => {
        if (err) {
          console.error('Error creating new games table:', err);
        } else {
          console.log('✓ Created new games table structure');
        }
      });

      // Copy data from old games table to new one
      db.run(`
        INSERT OR IGNORE INTO games_new (
          id, home_team_id, away_team_id, league_id, season, week, 
          game_date, game_time, venue, home_score, away_score, 
          quarter, is_live, is_completed, created_at, updated_at
        )
        SELECT 
          id, home_team_id, away_team_id, league_id, season, week,
          game_date, game_time, venue, home_score, away_score,
          quarter, is_live, is_completed, created_at, updated_at
        FROM games
      `, (err) => {
        if (err) {
          console.error('Error copying games data:', err);
        } else {
          console.log('✓ Copied games data to new structure');
        }
      });

      // Drop old games table and rename new one
      db.run(`DROP TABLE IF EXISTS games`, (err) => {
        if (err) {
          console.error('Error dropping old games table:', err);
        } else {
          console.log('✓ Dropped old games table');
        }
      });

      db.run(`ALTER TABLE games_new RENAME TO games`, (err) => {
        if (err) {
          console.error('Error renaming games table:', err);
        } else {
          console.log('✓ Renamed games_new to games');
        }
      });

      // Recreate indexes
      const indexes = [
        { name: 'idx_games_league_season', query: 'CREATE INDEX IF NOT EXISTS idx_games_league_season ON games (league_id, season)' },
        { name: 'idx_games_date', query: 'CREATE INDEX IF NOT EXISTS idx_games_date ON games (game_date)' },
        { name: 'idx_games_home_team', query: 'CREATE INDEX IF NOT EXISTS idx_games_home_team ON games (home_team_id)' },
        { name: 'idx_games_away_team', query: 'CREATE INDEX IF NOT EXISTS idx_games_away_team ON games (away_team_id)' },
        { name: 'idx_teams_league', query: 'CREATE INDEX IF NOT EXISTS idx_teams_league ON teams (league_id)' },
        { name: 'idx_teams_conference', query: 'CREATE INDEX IF NOT EXISTS idx_teams_conference ON teams (conference)' },
        { name: 'idx_teams_roster', query: 'CREATE INDEX IF NOT EXISTS idx_teams_roster ON teams (roster_id)' },
        { name: 'idx_venues_home_team', query: 'CREATE INDEX IF NOT EXISTS idx_venues_home_team ON venues (home_team_id)' }
      ];

      let completedIndexes = 0;
      indexes.forEach(index => {
        db.run(index.query, (err) => {
          if (err) {
            console.error(`Error creating ${index.name} index:`, err);
          } else {
            console.log(`✓ Created ${index.name} index`);
          }
          completedIndexes++;
          if (completedIndexes === indexes.length) {
            console.log('✓ All indexes created successfully');
          }
        });
      });

      console.log('Database migration completed successfully!');
      resolve();
    });
  });
};

// Run migration if called directly
if (require.main === module) {
  migrateSchema()
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

module.exports = { migrateSchema };
