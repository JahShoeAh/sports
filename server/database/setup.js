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
          logoUrl TEXT,
          sport TEXT NOT NULL,
          level TEXT NOT NULL,
          isActive BOOLEAN DEFAULT 1,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Teams table
      db.run(`
        CREATE TABLE IF NOT EXISTS teams (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          city TEXT NOT NULL,
          abbreviation TEXT NOT NULL,
          logoUrl TEXT,
          leagueId TEXT NOT NULL,
          conference TEXT,
          division TEXT,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (leagueId) REFERENCES leagues (id)
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
          homeTeamId TEXT,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (homeTeamId) REFERENCES teams (id)
        )
      `);

      // Games table
      db.run(`
        CREATE TABLE IF NOT EXISTS games (
          id TEXT PRIMARY KEY,
          homeTeamId TEXT NOT NULL,
          awayTeamId TEXT NOT NULL,
          leagueId TEXT NOT NULL,
          season TEXT NOT NULL,
          week INTEGER,
          gameTime DATETIME NOT NULL,
          venueId TEXT,
          homeScore INTEGER,
          awayScore INTEGER,
          homeLineScore TEXT,
          awayLineScore TEXT,
          leadChanges INTEGER,
          quarter INTEGER,
          isLive BOOLEAN DEFAULT 0,
          isCompleted BOOLEAN DEFAULT 0,
          apiGameId INTEGER,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (homeTeamId) REFERENCES teams (id),
          FOREIGN KEY (awayTeamId) REFERENCES teams (id),
          FOREIGN KEY (leagueId) REFERENCES leagues (id),
          FOREIGN KEY (venueId) REFERENCES venues (id)
        )
      `);

      // Players table
      db.run(`
        CREATE TABLE IF NOT EXISTS players (
          id TEXT PRIMARY KEY,
          teamId TEXT NOT NULL,
          displayName TEXT NOT NULL,
          firstName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          jerseyNumber INTEGER,
          position TEXT,
          birthdate TEXT,
          heightInches INTEGER,
          weightLbs INTEGER,
          nationality TEXT,
          college TEXT,
          photoUrl TEXT,
          injuryStatus TEXT,
          draftYear INTEGER,
          draftPickOverall INTEGER,
          active INTEGER NOT NULL DEFAULT 1,
          apiPlayerId INTEGER,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (teamId) REFERENCES teams (id) ON DELETE SET NULL
        )
      `);

      // Rosters table
      db.run(`
        CREATE TABLE IF NOT EXISTS rosters (
          id TEXT PRIMARY KEY,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // PlayerStats table
      db.run(`
        CREATE TABLE IF NOT EXISTS playerStats (
          gameId TEXT NOT NULL,
          playerId TEXT NOT NULL,
          teamId TEXT NOT NULL,
          points INTEGER DEFAULT 0,
          pos TEXT,
          min TEXT,
          fgm INTEGER DEFAULT 0,
          fga INTEGER DEFAULT 0,
          fgp TEXT,
          ftm INTEGER DEFAULT 0,
          fta INTEGER DEFAULT 0,
          ftp TEXT,
          tpm INTEGER DEFAULT 0,
          tpa INTEGER DEFAULT 0,
          tpp TEXT,
          offReb INTEGER DEFAULT 0,
          defReb INTEGER DEFAULT 0,
          totReb INTEGER DEFAULT 0,
          assists INTEGER DEFAULT 0,
          pFouls INTEGER DEFAULT 0,
          steals INTEGER DEFAULT 0,
          turnovers INTEGER DEFAULT 0,
          blocks INTEGER DEFAULT 0,
          plusMinus TEXT,
          comment TEXT,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (gameId, playerId),
          FOREIGN KEY (gameId) REFERENCES games (id),
          FOREIGN KEY (playerId) REFERENCES players (id),
          FOREIGN KEY (teamId) REFERENCES teams (id)
        )
      `);

      // Data freshness tracking
      db.run(`
        CREATE TABLE IF NOT EXISTS dataFreshness (
          leagueId TEXT PRIMARY KEY,
          lastUpdated DATETIME NOT NULL,
          lastSuccessfulFetch DATETIME,
          fetchAttempts INTEGER DEFAULT 0,
          lastError TEXT,
          FOREIGN KEY (leagueId) REFERENCES leagues (id)
        )
      `);

      // Create indexes for better performance
      db.run(`CREATE INDEX IF NOT EXISTS idxGamesLeagueSeason ON games (leagueId, season)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxGamesTime ON games (gameTime)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxGamesHomeTeam ON games (homeTeamId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxGamesAwayTeam ON games (awayTeamId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxGamesVenue ON games (venueId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxTeamsLeague ON teams (leagueId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxTeamsConference ON teams (conference)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxVenuesHomeTeam ON venues (homeTeamId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxPlayersTeam ON players (teamId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxPlayersDisplayName ON players (displayName)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxPlayersPosition ON players (position)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxPlayersActive ON players (active)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxPlayersApiId ON players (apiPlayerId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxPlayerStatsGame ON playerStats (gameId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxPlayerStatsPlayer ON playerStats (playerId)`);
      db.run(`CREATE INDEX IF NOT EXISTS idxPlayerStatsTeam ON playerStats (teamId)`);

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
