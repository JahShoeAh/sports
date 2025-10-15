const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fetch = require('node-fetch');
const config = require('../config');

const API_BASE = 'https://v2.nba.api-sports.io';
const API_KEY = process.env.NBA_API_KEY || '9316aa1d2d0c2d55eb84b0dc566fc21a';
const SEASON = '2022';
const NBA_LEAGUE_ID = 12;

const db = new sqlite3.Database(config.dbPath);

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function sanitizeId(text) {
  return text.toUpperCase().replace(/[^A-Z0-9]+/g, '_');
}

function toGameId(dateStr, awayAbbr, homeAbbr) {
  const compact = dateStr.replace(/-/g, '');
  return `NBA_${compact}_${awayAbbr}_${homeAbbr}`;
}

function seasonLabel(dateStr) {
  // dateStr is YYYY-MM-DD
  if (dateStr <= '2023-04-09') return '2022-23 Regular';
  if (dateStr >= '2023-04-11') return '2023 Playoffs';
  return '2022-23 Regular';
}

async function apiGet(pathname, params = {}) {
  const url = new URL(API_BASE + pathname);
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, String(v)));
  const res = await fetch(url.toString(), {
    headers: {
      'x-rapidapi-key': API_KEY,
      'x-rapidapi-host': 'v2.nba.api-sports.io'
    }
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`API ${url} failed: ${res.status} ${body}`);
  }
  const json = await res.json();
  return json.response || json.results || json;
}

async function fetchTeamsMap() {
  // Get teams from our database since API teams endpoint seems to have issues
  const dbTeams = await loadDbTeams();
  
  // Create a mapping from API team IDs to our database team IDs
  // We'll use a hardcoded mapping based on common NBA team IDs
  const apiToDbMapping = {
    1: 'NBA_ATL',    // Atlanta Hawks
    2: 'NBA_BOS',    // Boston Celtics  
    3: 'NBA_BKN',    // Brooklyn Nets
    4: 'NBA_CHA',    // Charlotte Hornets
    5: 'NBA_CHI',    // Chicago Bulls
    6: 'NBA_CLE',    // Cleveland Cavaliers
    7: 'NBA_DAL',    // Dallas Mavericks
    8: 'NBA_DEN',    // Denver Nuggets
    9: 'NBA_DET',    // Detroit Pistons
    10: 'NBA_GSW',   // Golden State Warriors
    11: 'NBA_HOU',   // Houston Rockets
    12: 'NBA_IND',   // Indiana Pacers
    13: 'NBA_LAC',   // Los Angeles Clippers
    14: 'NBA_LAL',   // Los Angeles Lakers
    15: 'NBA_MEM',   // Memphis Grizzlies
    16: 'NBA_MIA',   // Miami Heat
    17: 'NBA_MIL',   // Milwaukee Bucks
    18: 'NBA_MIN',   // Minnesota Timberwolves
    19: 'NBA_NOP',   // New Orleans Pelicans
    20: 'NBA_NYK',   // New York Knicks
    21: 'NBA_OKC',   // Oklahoma City Thunder
    22: 'NBA_ORL',    // Orlando Magic
    23: 'NBA_PHI',   // Philadelphia 76ers
    24: 'NBA_PHX',   // Phoenix Suns
    25: 'NBA_POR',   // Portland Trail Blazers
    26: 'NBA_SAC',   // Sacramento Kings
    27: 'NBA_SAS',   // San Antonio Spurs
    28: 'NBA_TOR',   // Toronto Raptors
    29: 'NBA_UTA',   // Utah Jazz
    30: 'NBA_WAS'    // Washington Wizards
  };
  
  return { apiToDbMapping, dbTeams };
}

function upsertVenue(venue) {
  return new Promise((resolve, reject) => {
    if (!venue || !venue.name) return resolve(null);
    const name = venue.name.trim();
    const city = venue.city || null;
    const state = venue.state || null;
    const country = venue.country || null;

    // Try to find existing by name + city
    db.get('SELECT id FROM venues WHERE UPPER(name)=UPPER(?) AND (city IS ? OR UPPER(city)=UPPER(?))', [name, city, city], (err, row) => {
      if (err) return reject(err);
      if (row) return resolve(row.id);
      const venueId = `VENUE_${sanitizeId(name)}`;
      const stmt = db.prepare('INSERT OR REPLACE INTO venues (id, name, city, state, country) VALUES (?, ?, ?, ?, ?)');
      stmt.run([venueId, name, city || null, state || null, country || null], (e) => {
        if (e) return reject(e);
        resolve(venueId);
      });
      stmt.finalize();
    });
  });
}

function saveGameRow(g) {
  return new Promise((resolve, reject) => {
    const stmt = db.prepare(`
      INSERT OR REPLACE INTO games 
      (id, home_team_id, away_team_id, league_id, season, week, game_date, game_time, venue_id, home_score, away_score, quarter, is_live, is_completed, box_score)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    stmt.run([
      g.id, g.home_team_id, g.away_team_id, 'NBA', g.season, null,
      g.game_date, g.game_time, g.venue_id || null, g.home_score, g.away_score,
      g.quarter, g.is_live ? 1 : 0, g.is_completed ? 1 : 0,
      g.box_score ? JSON.stringify(g.box_score) : null
    ], (err) => {
      if (err) return reject(err);
      resolve();
    });
    stmt.finalize();
  });
}

async function fetchGamesAndBoxScores(teamMaps) {
  console.log(`Fetching games for season ${SEASON}...`);
  const resp = await apiGet('/games', { season: SEASON });
  console.log(`Received ${resp ? resp.length : 0} games`);
  if (!Array.isArray(resp) || resp.length === 0) {
    console.log('No games returned from API');
    return;
  }

  for (const g of resp) {
    const date = (g.date && g.date.start) ? g.date.start.slice(0, 10) : (g.date && g.date.split('T')[0]);
    const time = (g.date && g.date.start) ? g.date.start.slice(11, 19) : (g.date && g.date.split('T')[1]?.slice(0,8)) || '00:00:00';
    
    // Extract team abbreviations from API response
    const homeTeamId = g.teams?.home?.id;
    const awayTeamId = g.teams?.visitors?.id || g.teams?.away?.id;
    const homeAbbr = g.teams?.home?.code || 'UNK';
    const awayAbbr = g.teams?.visitors?.code || g.teams?.away?.code || 'UNK';
    
    const homeTm = { teamId: teamMaps.apiToDbMapping[homeTeamId] || `NBA_${homeAbbr}`, abbr: homeAbbr };
    const awayTm = { teamId: teamMaps.apiToDbMapping[awayTeamId] || `NBA_${awayAbbr}`, abbr: awayAbbr };
    const id = toGameId(date, awayTm.abbr, homeTm.abbr);
    const seasonLbl = seasonLabel(date);
    const homeScore = g.scores?.home?.points ?? g.scores?.home ?? null;
    const awayScore = g.scores?.visitors?.points ?? g.scores?.away ?? null;
    const finished = (g.status?.long || g.status) === 'Finished' || (g.periods?.current && g.periods?.total && g.periods.current >= g.periods.total);
    const quarter = g.periods?.current || null;

    let venue_id = null;
    if (g.arena || g.venue) {
      venue_id = await upsertVenue({
        name: g.arena?.name || g.venue?.name,
        city: g.arena?.city || g.venue?.city,
        state: g.arena?.state || g.venue?.state,
        country: g.arena?.country || g.venue?.country,
      });
    }

    // Box score
    let boxScore = null;
    try {
      const statsResp = await apiGet('/games/statistics', { id: g.id });
      if (Array.isArray(statsResp) && statsResp.length > 0) {
        // Keep raw stats payload; API route will shape for client
        boxScore = statsResp[0];
      }
    } catch (e) {
      // ignore per-game failures
    }

    await saveGameRow({
      id,
      home_team_id: homeTm.teamId,
      away_team_id: awayTm.teamId,
      game_date: date,
      game_time: time,
      home_score: homeScore,
      away_score: awayScore,
      quarter,
      is_live: false,
      is_completed: finished ? 1 : 0,
      venue_id,
      season: seasonLbl,
      box_score: boxScore
    });

    await sleep(120); // gentle pacing
  }
}

function inchesFromHeight(feet, inches) {
  const f = parseInt(feet || '0', 10) || 0;
  const i = parseInt(inches || '0', 10) || 0;
  return f * 12 + i;
}

function loadDbTeams() {
  return new Promise((resolve, reject) => {
    const byCode = new Map();
    const byName = new Map();
    db.all('SELECT id, abbreviation, name, city FROM teams WHERE league_id = ?',[ 'NBA' ], (err, rows) => {
      if (err) return reject(err);
      for (const r of rows) {
        const code = String(r.abbreviation || '').toUpperCase();
        const nameKey = String(r.name || '').toUpperCase();
        const cityNameKey = `${String(r.city||'').toUpperCase()} ${nameKey}`.trim();
        if (code) byCode.set(code, r.id);
        if (nameKey) byName.set(nameKey, r.id);
        if (cityNameKey) byName.set(cityNameKey, r.id);
      }
      resolve({ byCode, byName });
    });
  });
}

async function importPlayers(teamMaps) {
  await new Promise((resolve, reject) => db.run('DELETE FROM players', (e)=> e?reject(e):resolve()));
  const insertStmt = db.prepare(`
    INSERT OR REPLACE INTO players 
    (id, team_id, display_name, first_name, last_name, jersey_number, primary_position, secondary_position, birthdate, height_inches, weight_lbs, nationality, photo_url, injury_status, draft_year, draft_pick_overall, active)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  // Fetch players per team using API team IDs
  for (const [apiTeamId, dbTeamId] of Object.entries(teamMaps.apiToDbMapping)) {
    const resp = await apiGet('/players', { season: SEASON, team: apiTeamId });
    if (!Array.isArray(resp) || resp.length === 0) continue;

    console.log(`Importing ${resp.length} players for team ${dbTeamId} (API ID: ${apiTeamId})`);

    for (const p of resp) {
      const id = String(p.id);
      const first = p.firstname || p.firstName || '';
      const last = p.lastname || p.lastName || '';
      const display = (p.name && (p.name.display || p.name.full)) || `${first} ${last}`.trim();
      const jersey = p.leagues?.standard?.jersey || p.jersey || null;
      const pos = p.leagues?.standard?.pos || p.position || 'G';
      const birthdate = p.birth?.date || p.birth?.birthday || '1990-01-01';
      const heightFeet = p.height?.feets || p.height?.feet;
      const heightInchesOnly = p.height?.inches;
      const heightInches = inchesFromHeight(heightFeet, heightInchesOnly) || 75;
      const weight = parseInt(p.weight?.pounds || p.weight?.lbs || '200', 10);
      const nationality = p.nationality || null;
      const photo = p.photo || null;
      const draftYear = p.nba?.start || null;
      const draftPickOverall = null;
      const active = p.active === true || p.nba?.pro === true ? 1 : 1;

      insertStmt.run([
        id, dbTeamId, display, first, last, jersey, pos, null, birthdate, heightInches, weight, nationality, photo, null, draftYear, draftPickOverall, active
      ]);
    }

    await sleep(150);
  }

  insertStmt.finalize();
}

async function main() {
  try {
    console.log('Fetching teams...');
    const teamMap = await fetchTeamsMap();
    console.log('Importing games & box scores...');
    await fetchGamesAndBoxScores(teamMap);
    console.log('Importing players...');
    await importPlayers(teamMap);
    console.log('Done.');
  } catch (e) {
    console.error('Import failed:', e);
    process.exitCode = 1;
  } finally {
    db.close();
  }
}

if (require.main === module) {
  main();
}


