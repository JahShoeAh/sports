const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const config = require('../config');

// Ensure data directory exists
const dataDir = path.dirname(config.dbPath);
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// Create database connection
const db = new sqlite3.Database(config.dbPath);

// Database schema
const createTables = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Leagues table
      db.run(`
        CREATE TABLE IF NOT EXISTS leagues (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          abbreviation TEXT NOT NULL,
          logo_url TEXT,
          sport TEXT NOT NULL,
          level TEXT NOT NULL,
          season TEXT NOT NULL,
          is_active BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Rosters table (must be created before teams due to foreign key)
      db.run(`
        CREATE TABLE IF NOT EXISTS rosters (
          id TEXT PRIMARY KEY,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Teams table
      db.run(`
        CREATE TABLE IF NOT EXISTS teams (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          city TEXT NOT NULL,
          abbreviation TEXT NOT NULL,
          logo_url TEXT,
          league_id TEXT NOT NULL,
          conference TEXT,
          division TEXT,
          roster_id TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (league_id) REFERENCES leagues (id),
          FOREIGN KEY (roster_id) REFERENCES rosters (id)
        )
      `);

      // Venues table
      db.run(`
        CREATE TABLE IF NOT EXISTS venues (
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
      `);

      // Games table
      db.run(`
        CREATE TABLE IF NOT EXISTS games (
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
      `);

      // Data freshness tracking
      db.run(`
        CREATE TABLE IF NOT EXISTS data_freshness (
          league_id TEXT PRIMARY KEY,
          last_updated DATETIME NOT NULL,
          last_successful_fetch DATETIME,
          fetch_attempts INTEGER DEFAULT 0,
          last_error TEXT,
          FOREIGN KEY (league_id) REFERENCES leagues (id)
        )
      `);

      // Create indexes for better performance
      db.run(`CREATE INDEX IF NOT EXISTS idx_games_league_season ON games (league_id, season)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_games_date ON games (game_date)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_games_home_team ON games (home_team_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_games_away_team ON games (away_team_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_games_venue ON games (venue_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_teams_league ON teams (league_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_teams_conference ON teams (conference)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_teams_roster ON teams (roster_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_venues_home_team ON venues (home_team_id)`);

      db.run(`PRAGMA journal_mode = WAL`, (err) => {
        if (err) {
          console.error('Error setting WAL mode:', err);
          reject(err);
        } else {
          console.log('Database tables created successfully');
          resolve();
        }
      });
    });
  });
};

// Initialize database
const initializeDatabase = async () => {
  try {
    await createTables();
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  } finally {
    db.close();
  }
};

// Run setup if called directly
if (require.main === module) {
  initializeDatabase();
}

module.exports = { initializeDatabase, db };
