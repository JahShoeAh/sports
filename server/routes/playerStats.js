const express = require('express');
const router = express.Router();
const database = require('../services/database');

// Transform player stats data for API response
const transformPlayerStats = (stats) => ({
  gameId: stats.gameId,
  playerId: stats.playerId,
  teamId: stats.teamId,
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
  comment: stats.comment,
  player: {
    id: stats.playerId,
    displayName: stats.displayName,
    firstName: stats.firstName,
    lastName: stats.lastName,
    jerseyNumber: stats.jerseyNumber,
    position: stats.position
  },
  team: {
    id: stats.teamId,
    name: stats.teamName,
    city: stats.teamCity,
    abbreviation: stats.teamAbbreviation
  },
  game: {
    id: stats.gameId,
    gameDate: stats.gameDate,
    homeTeamId: stats.homeTeamId,
    awayTeamId: stats.awayTeamId
  },
  createdAt: stats.createdAt,
  updatedAt: stats.updatedAt
});

// GET /api/playerStats - Get player stats with query filters
router.get('/', async (req, res) => {
  try {
    const { gameId, playerId, teamId } = req.query;
    
    let stats;
    
    if (gameId && playerId) {
      // Get specific player stats for a game
      const stat = await database.getPlayerStats(gameId, playerId);
      stats = stat ? [stat] : [];
    } else if (gameId) {
      // Get all stats for a game
      stats = await database.getPlayerStatsByGame(gameId);
    } else if (playerId) {
      // Get all stats for a player
      stats = await database.getPlayerStatsByPlayer(playerId);
    } else if (teamId) {
      // Get all stats for a team
      stats = await database.getPlayerStatsByTeam(teamId);
    } else {
      return res.status(400).json({
        success: false,
        message: 'At least one filter parameter (gameId, playerId, teamId) is required'
      });
    }
    
    // Transform data for API response
    const transformedStats = stats.map(transformPlayerStats);
    
    res.json({
      success: true,
      data: transformedStats,
      count: transformedStats.length,
      filters: {
        gameId: gameId || null,
        playerId: playerId || null,
        teamId: teamId || null
      }
    });

  } catch (error) {
    console.error('Error fetching player stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/playerStats/game/:gameId - Get all stats for a game
router.get('/game/:gameId', async (req, res) => {
  try {
    const { gameId } = req.params;
    
    const stats = await database.getPlayerStatsByGame(gameId);
    const transformedStats = stats.map(transformPlayerStats);
    
    res.json({
      success: true,
      data: transformedStats,
      count: transformedStats.length,
      gameId: gameId
    });

  } catch (error) {
    console.error('Error fetching game stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/playerStats/player/:playerId - Get all stats for a player
router.get('/player/:playerId', async (req, res) => {
  try {
    const { playerId } = req.params;
    
    const stats = await database.getPlayerStatsByPlayer(playerId);
    const transformedStats = stats.map(transformPlayerStats);
    
    res.json({
      success: true,
      data: transformedStats,
      count: transformedStats.length,
      playerId: playerId
    });

  } catch (error) {
    console.error('Error fetching player stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/playerStats/team/:teamId - Get all stats for a team
router.get('/team/:teamId', async (req, res) => {
  try {
    const { teamId } = req.params;
    const { gameId } = req.query;
    
    const stats = await database.getPlayerStatsByTeam(teamId, gameId);
    const transformedStats = stats.map(transformPlayerStats);
    
    res.json({
      success: true,
      data: transformedStats,
      count: transformedStats.length,
      teamId: teamId,
      gameId: gameId || null
    });

  } catch (error) {
    console.error('Error fetching team stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/playerStats/:gameId/:playerId - Get specific player stats for a game
router.get('/:gameId/:playerId', async (req, res) => {
  try {
    const { gameId, playerId } = req.params;
    
    const stats = await database.getPlayerStats(gameId, playerId);
    
    if (!stats) {
      return res.status(404).json({
        success: false,
        message: 'Player stats not found for this game'
      });
    }
    
    const transformedStats = transformPlayerStats(stats);
    
    res.json({
      success: true,
      data: transformedStats
    });

  } catch (error) {
    console.error('Error fetching player stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// POST /api/playerStats - Create new player stats
router.post('/', async (req, res) => {
  try {
    const statsData = req.body;
    
    // Validate required fields
    const requiredFields = ['gameId', 'playerId', 'teamId'];
    const missingFields = requiredFields.filter(field => !statsData[field]);
    
    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
        missingFields: missingFields
      });
    }
    
    await database.savePlayerStats(statsData);
    
    // Fetch the created stats to return
    const stats = await database.getPlayerStats(statsData.gameId, statsData.playerId);
    const transformedStats = transformPlayerStats(stats);
    
    res.status(201).json({
      success: true,
      data: transformedStats,
      message: 'Player stats created successfully'
    });

  } catch (error) {
    console.error('Error creating player stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// PUT /api/playerStats/:gameId/:playerId - Update player stats
router.put('/:gameId/:playerId', async (req, res) => {
  try {
    const { gameId, playerId } = req.params;
    const statsData = req.body;
    
    // Ensure the IDs match the URL parameters
    statsData.gameId = gameId;
    statsData.playerId = playerId;
    
    await database.savePlayerStats(statsData);
    
    // Fetch the updated stats to return
    const stats = await database.getPlayerStats(gameId, playerId);
    const transformedStats = transformPlayerStats(stats);
    
    res.json({
      success: true,
      data: transformedStats,
      message: 'Player stats updated successfully'
    });

  } catch (error) {
    console.error('Error updating player stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// DELETE /api/playerStats/:gameId/:playerId - Delete player stats
router.delete('/:gameId/:playerId', async (req, res) => {
  try {
    const { gameId, playerId } = req.params;
    
    // Check if stats exist
    const existingStats = await database.getPlayerStats(gameId, playerId);
    
    if (!existingStats) {
      return res.status(404).json({
        success: false,
        message: 'Player stats not found for this game'
      });
    }
    
    const deletedCount = await database.deletePlayerStats(gameId, playerId);
    
    res.json({
      success: true,
      message: 'Player stats deleted successfully',
      deletedCount: deletedCount
    });

  } catch (error) {
    console.error('Error deleting player stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
