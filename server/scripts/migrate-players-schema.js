const sqlite3 = require('sqlite3').verbose();
const config = require('../config');

const db = new sqlite3.Database(config.dbPath);

const run = (sql, params = []) => new Promise((resolve, reject) => {
  db.run(sql, params, function(err) {
    if (err) return reject(err);
    resolve(this);
  });
});

const migrate = async () => {
  try {
    console.log('Starting players schema migration...');
    await run('BEGIN TRANSACTION');

    await run('DROP TABLE IF EXISTS players');

    await run(`
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

    await run(`CREATE INDEX IF NOT EXISTS idxPlayersTeam ON players (teamId)`);
    await run(`CREATE INDEX IF NOT EXISTS idxPlayersDisplayName ON players (displayName)`);
    await run(`CREATE INDEX IF NOT EXISTS idxPlayersPosition ON players (position)`);
    await run(`CREATE INDEX IF NOT EXISTS idxPlayersActive ON players (active)`);
    await run(`CREATE INDEX IF NOT EXISTS idxPlayersApiId ON players (apiPlayerId)`);

    await run('COMMIT');
    console.log('Players schema migration completed.');
  } catch (err) {
    console.error('Migration failed, rolling back:', err);
    try { await run('ROLLBACK'); } catch (_) {}
    process.exit(1);
  } finally {
    db.close();
  }
};

if (require.main === module) {
  migrate();
}

module.exports = { migrate };


