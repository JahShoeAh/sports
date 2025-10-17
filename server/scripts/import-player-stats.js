const fs = require('fs');
const path = require('path');
const database = require('../services/database');

// Team ID mapping from API team IDs to internal team IDs
const teamIdMap = {
  1: 'NBA_ATL', 2: 'NBA_BOS', 4: 'NBA_BKN', 5: 'NBA_CHA', 6: 'NBA_CHI', 7: 'NBA_CLE',
  8: 'NBA_DAL', 9: 'NBA_DEN', 10: 'NBA_DET', 11: 'NBA_GSW', 14: 'NBA_HOU', 15: 'NBA_IND',
  16: 'NBA_LAC', 17: 'NBA_LAL', 19: 'NBA_MEM', 20: 'NBA_MIA', 21: 'NBA_MIL', 22: 'NBA_MIN',
  23: 'NBA_NOP', 24: 'NBA_NYK', 25: 'NBA_OKC', 26: 'NBA_ORL', 27: 'NBA_PHI', 28: 'NBA_PHX',
  29: 'NBA_POR', 30: 'NBA_SAC', 31: 'NBA_SAS', 38: 'NBA_TOR', 40: 'NBA_UTA', 41: 'NBA_WAS'
};

// Statistics to track import progress
const stats = {
  totalProcessed: 0,
  successfullyImported: 0,
  skipped: {
    gameNotFound: 0,
    playerNotFound: 0,
    teamNotFound: 0,
    other: 0
  },
  skippedEntries: []
};

// Load raw stats data
function loadRawStats() {
  const filePath = path.join(__dirname, '../raw_api/raw-stats-4-8.json');
  
  try {
    const rawData = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(rawData);
  } catch (error) {
    console.error('Error loading raw stats file:', error);
    process.exit(1);
  }
}

// Build lookup maps for game and player IDs
async function buildLookupMaps(rawStats) {
  console.log('Building lookup maps...');
  
  // Extract all unique API IDs from the raw data
  const apiGameIds = new Set();
  const apiPlayerIds = new Set();
  
  rawStats.games.forEach(game => {
    game.data.response.forEach(stat => {
      apiGameIds.add(stat.game.id);
      apiPlayerIds.add(stat.player.id);
    });
  });
  
  console.log(`Found ${apiGameIds.size} unique game IDs and ${apiPlayerIds.size} unique player IDs`);
  
  // Query database for game mappings
  const gameMappings = await new Promise((resolve, reject) => {
    database.db.all(`
      SELECT id, apiGameId FROM games 
      WHERE apiGameId IN (${Array.from(apiGameIds).map(() => '?').join(',')})
    `, Array.from(apiGameIds), (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
  
  const gameIdMap = {};
  gameMappings.forEach(game => {
    gameIdMap[game.apiGameId] = game.id;
  });
  
  console.log(`Mapped ${gameMappings.length} games`);
  
  // Query database for player mappings
  const playerMappings = await new Promise((resolve, reject) => {
    database.db.all(`
      SELECT id, apiPlayerId FROM players 
      WHERE apiPlayerId IN (${Array.from(apiPlayerIds).map(() => '?').join(',')})
    `, Array.from(apiPlayerIds), (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
  
  const playerIdMap = {};
  playerMappings.forEach(player => {
    playerIdMap[player.apiPlayerId] = player.id;
  });
  
  console.log(`Mapped ${playerMappings.length} players`);
  
  return { gameIdMap, playerIdMap };
}

// Transform a single stat entry
function transformStatEntry(statEntry, gameIdMap, playerIdMap) {
  const { player, team, game, ...stats } = statEntry;
  
  // Map IDs
  const internalGameId = gameIdMap[game.id];
  const internalPlayerId = playerIdMap[player.id];
  const internalTeamId = teamIdMap[team.id];
  
  // Check if all required mappings exist
  if (!internalGameId) {
    return { error: 'gameNotFound', gameId: game.id };
  }
  
  if (!internalPlayerId) {
    return { error: 'playerNotFound', playerId: player.id };
  }
  
  if (!internalTeamId) {
    return { error: 'teamNotFound', teamId: team.id };
  }
  
  // Return transformed stat entry
  return {
    gameId: internalGameId,
    playerId: internalPlayerId,
    teamId: internalTeamId,
    points: stats.points,
    pos: stats.pos,
    min: stats.min,
    fgm: stats.fgm,
    fga: stats.fga,
    fgp: stats.fgp,
    ftm: stats.ftm,
    fta: stats.fta,
    ftp: stats.ftp,
    tpm: stats.tpm,
    tpa: stats.tpa,
    tpp: stats.tpp,
    offReb: stats.offReb,
    defReb: stats.defReb,
    totReb: stats.totReb,
    assists: stats.assists,
    pFouls: stats.pFouls,
    steals: stats.steals,
    turnovers: stats.turnovers,
    blocks: stats.blocks,
    plusMinus: stats.plusMinus,
    comment: stats.comment
  };
}

// Process a single stat entry
async function processStatEntry(statEntry, gameIdMap, playerIdMap) {
  stats.totalProcessed++;
  
  const transformed = transformStatEntry(statEntry, gameIdMap, playerIdMap);
  
  if (transformed.error) {
    // Track skipped entry
    stats.skipped[transformed.error]++;
    stats.skippedEntries.push({
      error: transformed.error,
      player: statEntry.player,
      team: statEntry.team,
      game: statEntry.game,
      reason: getSkipReason(transformed.error, transformed)
    });
    
    if (stats.skippedEntries.length <= 10) {
      console.log(`Skipped: ${getSkipReason(transformed.error, transformed)}`);
    }
    
    return false;
  }
  
  try {
    await database.savePlayerStats(transformed);
    stats.successfullyImported++;
    
    if (stats.successfullyImported % 50 === 0) {
      console.log(`Imported ${stats.successfullyImported} stats...`);
    }
    
    return true;
  } catch (error) {
    console.error('Error saving player stats:', error);
    stats.skipped.other++;
    stats.skippedEntries.push({
      error: 'other',
      player: statEntry.player,
      team: statEntry.team,
      game: statEntry.game,
      reason: `Database error: ${error.message}`
    });
    return false;
  }
}

// Get human-readable skip reason
function getSkipReason(error, transformed) {
  switch (error) {
    case 'gameNotFound':
      return `Game ID ${transformed.gameId} not found in database`;
    case 'playerNotFound':
      return `Player ID ${transformed.playerId} not found in database`;
    case 'teamNotFound':
      return `Team ID ${transformed.teamId} not found in teamIdMap`;
    default:
      return 'Unknown error';
  }
}

// Print final statistics
function printStats() {
  console.log('\n=== Import Statistics ===');
  console.log(`Total stats processed: ${stats.totalProcessed}`);
  console.log(`Successfully imported: ${stats.successfullyImported}`);
  console.log(`Skipped: ${Object.values(stats.skipped).reduce((a, b) => a + b, 0)}`);
  console.log(`  - Game not found: ${stats.skipped.gameNotFound}`);
  console.log(`  - Player not found: ${stats.skipped.playerNotFound}`);
  console.log(`  - Team not found: ${stats.skipped.teamNotFound}`);
  console.log(`  - Other errors: ${stats.skipped.other}`);
  
  if (stats.skippedEntries.length > 0) {
    console.log('\n=== Sample Skipped Entries ===');
    stats.skippedEntries.slice(0, 5).forEach(entry => {
      console.log(`${entry.reason} - Player: ${entry.player.firstname} ${entry.player.lastname} (${entry.player.id})`);
    });
    
    if (stats.skippedEntries.length > 5) {
      console.log(`... and ${stats.skippedEntries.length - 5} more`);
    }
  }
}

// Main import function
async function importPlayerStats() {
  try {
    console.log('Starting player stats import...');
    
    // Load raw data
    const rawStats = loadRawStats();
    console.log(`Loaded ${rawStats.games.length} games with player stats`);
    
    // Build lookup maps
    const { gameIdMap, playerIdMap } = await buildLookupMaps(rawStats);
    
    // Process each game's stats
    for (const game of rawStats.games) {
      console.log(`Processing game ${game.gameId} with ${game.data.response.length} player stats...`);
      
      for (const statEntry of game.data.response) {
        await processStatEntry(statEntry, gameIdMap, playerIdMap);
      }
    }
    
    // Print final statistics
    printStats();
    
    console.log('\nPlayer stats import completed!');
    
  } catch (error) {
    console.error('Error during import:', error);
    process.exit(1);
  } finally {
    // Close database connection
    database.close();
  }
}

// Run the import if this script is executed directly
if (require.main === module) {
  importPlayerStats();
}

module.exports = { importPlayerStats };
