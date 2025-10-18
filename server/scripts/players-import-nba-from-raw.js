const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();
const config = require('../config');

const db = new sqlite3.Database(config.dbPath);

const run = (sql, params = []) => new Promise((resolve, reject) => {
  db.run(sql, params, function(err) {
    if (err) return reject(err);
    resolve(this);
  });
});

const all = (sql, params = []) => new Promise((resolve, reject) => {
  db.all(sql, params, function(err, rows) {
    if (err) return reject(err);
    resolve(rows);
  });
});

const teamIdMap = {
  1: 'NBA_ATL', 2: 'NBA_BOS', 4: 'NBA_BKN', 5: 'NBA_CHA', 6: 'NBA_CHI', 7: 'NBA_CLE',
  8: 'NBA_DAL', 9: 'NBA_DEN', 10: 'NBA_DET', 11: 'NBA_GSW', 14: 'NBA_HOU', 15: 'NBA_IND',
  16: 'NBA_LAC', 17: 'NBA_LAL', 19: 'NBA_MEM', 20: 'NBA_MIA', 21: 'NBA_MIL', 22: 'NBA_MIN',
  23: 'NBA_NOP', 24: 'NBA_NYK', 25: 'NBA_OKC', 26: 'NBA_ORL', 27: 'NBA_PHI', 28: 'NBA_PHX',
  29: 'NBA_POR', 30: 'NBA_SAC', 31: 'NBA_SAS', 38: 'NBA_TOR', 40: 'NBA_UTA', 41: 'NBA_WAS'
};

function normalizeNameId(firstName, lastName) {
  const toAZ = (s) => (s || '').toUpperCase().replace(/[^A-Z\s]/g, ' ').replace(/\s+/g, ' ').trim();
  const first = toAZ(firstName);
  const last = toAZ(lastName);
  return `${first} ${last}`.trim();
}

function toIntOrNull(value) {
  if (value === null || value === undefined) return null;
  const n = parseInt(value, 10);
  return Number.isNaN(n) ? null : n;
}

function toHeightInches(height) {
  if (!height) return null;
  const feet = toIntOrNull(height.feets);
  const inches = toIntOrNull(height.inches);
  if (feet === null || inches === null) return null;
  return feet * 12 + inches;
}

async function importTeamFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const json = JSON.parse(content);
  const teamNumericId = toIntOrNull(json?.parameters?.team);
  const teamId = teamIdMap[teamNumericId];
  if (!teamId) {
    console.warn(`Skipping file ${path.basename(filePath)}: unknown team mapping for ${teamNumericId}`);
    return 0;
  }

  // Ensure team exists
  const teams = await all('SELECT id FROM teams WHERE id = ?', [teamId]);
  if (teams.length === 0) {
    console.warn(`Team ${teamId} not found in DB. Skipping ${path.basename(filePath)}.`);
    return 0;
  }

  const players = Array.isArray(json.response) ? json.response : [];

  // Build existing name-ID counts to ensure uniqueness
  const existing = await all('SELECT id FROM players');
  const usedIds = new Set(existing.map(r => r.id));

  const stmt = await new Promise((resolve, reject) => {
    const s = db.prepare(`
      INSERT OR REPLACE INTO players (
        id, teamId, displayName, firstName, lastName, jerseyNumber,
        position, birthdate, heightInches, weightLbs, nationality, college,
        photoUrl, injuryStatus, draftYear, draftPickOverall, active, apiPlayerId
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, (err) => err ? reject(err) : resolve(s));
  });

  let inserted = 0;
  for (const p of players) {
    const apiPlayerId = toIntOrNull(p.id);
    const firstName = p.firstname || null;
    const lastName = p.lastname || null;
    const displayName = [firstName, lastName].filter(Boolean).join(' ').trim();
    const position = p?.leagues?.standard?.pos || null;
    const birthdate = p?.birth?.date || null;
    const nationality = p?.birth?.country || null;
    const college = p?.college || null;
    const jerseyNumber = toIntOrNull(p?.leagues?.standard?.jersey);
    const heightInches = toHeightInches(p?.height);
    const weightLbs = toIntOrNull(p?.weight?.pounds);
    const active = (p?.leagues?.standard?.active === true) ? 1 : 0;

    // Generate unique ID
    let baseId = normalizeNameId(firstName, lastName);
    if (!baseId) {
      // fallback to API ID when name missing
      baseId = apiPlayerId ? `PLAYER ${apiPlayerId}` : `PLAYER UNKNOWN ${Date.now()}`;
    }
    let uniqueId = baseId;
    let suffix = 2;
    while (usedIds.has(uniqueId)) {
      uniqueId = `${baseId} ${suffix++}`;
    }
    usedIds.add(uniqueId);

    await new Promise((resolve, reject) => {
      stmt.run([
        uniqueId, teamId, displayName || uniqueId, firstName, lastName, jerseyNumber,
        position, birthdate, heightInches, weightLbs, nationality, college,
        null, null, null, null, active, apiPlayerId
      ], (err) => err ? reject(err) : resolve());
    });
    inserted++;
  }

  await new Promise((resolve) => stmt.finalize(() => resolve()))

  return inserted;
}

async function main() {
  try {
    console.log('Importing NBA players from raw files...');
    const rawDir = path.resolve(__dirname, '../raw_api');
    const files = fs.readdirSync(rawDir)
      .filter(f => /^raw-players-\d+\.json$/i.test(f))
      .map(f => path.join(rawDir, f))
      .sort();

    await run('BEGIN TRANSACTION');
    await run('DELETE FROM players');

    let total = 0;
    for (const file of files) {
      const count = await importTeamFile(file);
      console.log(`${path.basename(file)} -> ${count} players`);
      total += count;
    }

    await run('COMMIT');
    console.log(`Done. Inserted ${total} players.`);
  } catch (err) {
    console.error('Error during import, rolling back:', err);
    try { await run('ROLLBACK'); } catch (_) {}
    process.exit(1);
  } finally {
    db.close();
  }
}

if (require.main === module) {
  main();
}

module.exports = { main };


