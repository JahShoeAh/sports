const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const config = require('../config');

const db = new sqlite3.Database(config.dbPath);

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
      if (err) reject(err); else resolve(this);
    });
  });
}

function all(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, function(err, rows) {
      if (err) reject(err); else resolve(rows);
    });
  });
}

async function migrate() {
  console.log('Starting migration: add apiGameId and remove boxScore from games');
  await run('PRAGMA foreign_keys = OFF');
  await run('BEGIN TRANSACTION');

  try {
    await run(`
      CREATE TABLE IF NOT EXISTS games_new (
        id TEXT PRIMARY KEY,
        homeTeamId TEXT NOT NULL,
        awayTeamId TEXT NOT NULL,
        leagueId TEXT NOT NULL,
        season TEXT NOT NULL,
        week INTEGER,
        gameDate DATETIME NOT NULL,
        gameTime DATETIME NOT NULL,
        venueId TEXT,
        homeScore INTEGER,
        awayScore INTEGER,
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

    // Copy over existing data without boxScore; set apiGameId to NULL
    await run(`
      INSERT INTO games_new (
        id, homeTeamId, awayTeamId, leagueId, season, week, gameDate, gameTime,
        venueId, homeScore, awayScore, quarter, isLive, isCompleted, apiGameId, createdAt, updatedAt
      )
      SELECT 
        id, homeTeamId, awayTeamId, leagueId, season, week, gameDate, gameTime,
        venueId, homeScore, awayScore, quarter, isLive, isCompleted, NULL as apiGameId, createdAt, updatedAt
      FROM games
    `);

    await run('DROP TABLE games');
    await run('ALTER TABLE games_new RENAME TO games');

    // Ensure apiGameId is NULL for NBA 2024-25 Regular season
    await run(`
      UPDATE games 
      SET apiGameId = NULL 
      WHERE leagueId = 'NBA' AND season LIKE '2024-25%'
    `);

    await run('COMMIT');
    console.log('Migration completed successfully.');
  } catch (err) {
    console.error('Migration failed, rolling back:', err);
    await run('ROLLBACK');
    process.exitCode = 1;
  } finally {
    await run('PRAGMA foreign_keys = ON');
    db.close();
  }
}

if (require.main === module) {
  migrate();
}

module.exports = { migrate };


