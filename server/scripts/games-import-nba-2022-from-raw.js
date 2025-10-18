const fs = require('fs');
const path = require('path');
const database = require('../services/database');

// Helpers copied/adapted from fetch-nba-2023-24.js (no network use here)
function sanitizeId(text) {
  return String(text || '')
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function toGameId(dateStr, awayAbbr, homeAbbr) {
  const compact = String(dateStr).replace(/-/g, '');
  return `NBA_${compact}_${String(awayAbbr).toUpperCase()}_${String(homeAbbr).toUpperCase()}`;
}

function formatDateTimeFromStart(startIso) {
  // startIso like 2022-10-01T02:00:00.000Z
  if (!startIso) return { date: null, time: null };
  const d = startIso.split('T')[0];
  const tFull = startIso.split('T')[1] || '00:00:00Z';
  const t = tFull.slice(0, 8); // HH:MM:SS
  return { date: d, time: t };
}

function mapSeasonByStage(stage) {
  if (stage === 1) return '2022-23 Pre';
  if (stage === 2) return '2022-23 Regular';
  if (stage === 3) return '2023 Playoffs';
  return '2022-23 Regular';
}

async function loadTeamMaps() {
  const teams = await database.getTeams('NBA');
  const byCode = new Map();
  const byName = new Map();
  for (const t of teams) {
    const code = String(t.abbreviation || '').toUpperCase();
    const nameKey = String(t.name || '').toUpperCase();
    const cityNameKey = `${String(t.city || '').toUpperCase()} ${nameKey}`.trim();
    if (code) byCode.set(code, t.id);
    if (nameKey) byName.set(nameKey, t.id);
    if (cityNameKey) byName.set(cityNameKey, t.id);
  }
  return { byCode, byName };
}

async function buildVenueIndex() {
  const venues = await database.getVenues();
  const index = new Map();
  for (const v of venues) {
    const key = `${String(v.name || '').toUpperCase()}|${String(v.city || '').toUpperCase()}`;
    index.set(key, v.id);
  }
  return index;
}

async function findOrCreateVenue(venueIndex, venue) {
  if (!venue || !venue.name) return null;
  const name = String(venue.name).trim();
  const city = venue.city ? String(venue.city).trim() : '';
  const state = venue.state ? String(venue.state).trim() : null;
  const country = venue.country ? String(venue.country).trim() : null;
  const key = `${name.toUpperCase()}|${city.toUpperCase()}`;

  if (venueIndex.has(key)) {
    return venueIndex.get(key);
  }

  const id = `VENUE_${sanitizeId(name)}`;
  await database.saveVenue({ id, name, city: city || null, state, country, homeTeamId: null });
  venueIndex.set(key, id);
  return id;
}

function boolFromFinished(statusLong, periods) {
  const finished = String(statusLong || '').toLowerCase() === 'finished';
  if (finished) return true;
  const current = periods && typeof periods.current === 'number' ? periods.current : null;
  const total = periods && typeof periods.total === 'number' ? periods.total : null;
  if (current != null && total != null && current >= total) return true;
  return false;
}

async function main() {
  // Load raw JSON
  const rawPath = path.join(__dirname, '..', 'raw_api', 'raw-nba-2022.json');
  const raw = JSON.parse(fs.readFileSync(rawPath, 'utf8'));
  const games = Array.isArray(raw.response) ? raw.response : [];

  if (!games.length) {
    console.log('No games found in raw file.');
    return;
  }

  const teamMaps = await loadTeamMaps();
  const venueIndex = await buildVenueIndex();

  let inserted = 0;
  let skipped = 0;
  let createdVenues = 0;

  for (const g of games) {
    try {
      const { date: gameDate, time: gameTime } = formatDateTimeFromStart(g?.date?.start || (typeof g?.date === 'string' ? g.date : null));
      const stage = typeof g.stage === 'number' ? g.stage : 2;
      const season = mapSeasonByStage(stage);

      const homeCode = (g?.teams?.home?.code || g?.teams?.home?.abbr || '').toUpperCase();
      const awayCode = (g?.teams?.visitors?.code || g?.teams?.away?.code || g?.teams?.visitors?.abbr || '').toUpperCase();

      if (!homeCode || !awayCode) {
        skipped++;
        continue;
      }

      const homeTeamId = teamMaps.byCode.get(homeCode) || `NBA_${homeCode}`;
      const awayTeamId = teamMaps.byCode.get(awayCode) || `NBA_${awayCode}`;

      if (!homeTeamId || !awayTeamId || !gameDate || !gameTime) {
        skipped++;
        continue;
      }

      const id = toGameId(gameDate, awayCode, homeCode);

      // Scores and status
      const homeScore = g?.scores?.home?.points ?? null;
      const awayScore = g?.scores?.visitors?.points ?? g?.scores?.away?.points ?? null;
      const homeLineScore = Array.isArray(g?.scores?.home?.linescore) ? g.scores.home.linescore.map(s => Number(s)) : null;
      const awayLineScore = Array.isArray(g?.scores?.visitors?.linescore) ? g.scores.visitors.linescore.map(s => Number(s)) : null;
      const leadChanges = typeof g?.leadChanges === 'number' ? g.leadChanges : null;
      const quarter = typeof g?.periods?.current === 'number' ? g.periods.current : null;
      const isCompleted = boolFromFinished(g?.status?.long || g?.status, g?.periods);

      // Venue
      let venueId = null;
      if (g?.arena || g?.venue) {
        const venueInput = {
          name: g?.arena?.name || g?.venue?.name,
          city: g?.arena?.city || g?.venue?.city,
          state: g?.arena?.state || g?.venue?.state,
          country: g?.arena?.country || g?.venue?.country,
        };
        const beforeSize = venueIndex.size;
        venueId = await findOrCreateVenue(venueIndex, venueInput);
        if (venueIndex.size > beforeSize) createdVenues++;
      }

      await database.saveGame({
        id,
        homeTeamId,
        awayTeamId,
        leagueId: 'NBA',
        season,
        week: null,
        gameDate,
        gameTime,
        venueId: venueId || null,
        homeScore: typeof homeScore === 'number' ? homeScore : null,
        awayScore: typeof awayScore === 'number' ? awayScore : null,
        homeLineScore,
        awayLineScore,
        leadChanges,
        quarter,
        isLive: 0,
        isCompleted: isCompleted ? 1 : 0,
        apiGameId: g?.id ?? null,
      });

      inserted++;
    } catch (e) {
      skipped++;
    }
  }

  console.log(`Imported ${inserted} games. Skipped ${skipped}. New venues: ${createdVenues}.`);
}

if (require.main === module) {
  main()
    .then(() => database.close())
    .catch((e) => {
      console.error('Import failed:', e);
      database.close();
      process.exit(1);
    });
}

module.exports = { main };


