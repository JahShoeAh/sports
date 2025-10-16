const express = require('express');
const router = express.Router();
const database = require('../services/database');

// Helper function to calculate age from birthdate
const calculateAge = (birthdate) => {
  const today = new Date();
  const birth = new Date(birthdate);
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  
  return age;
};

// Helper function to format height
const formatHeight = (inches) => {
  const feet = Math.floor(inches / 12);
  const remainingInches = inches % 12;
  return `${feet}'${remainingInches}"`;
};

// Helper function to format weight
const formatWeight = (lbs) => {
  return `${lbs} lb`;
};

// Transform player data for API response
const transformPlayer = (player) => ({
  id: player.id,
  teamId: player.teamId,
  displayName: player.displayName,
  firstName: player.firstName,
  lastName: player.lastName,
  jerseyNumber: player.jerseyNumber,
  position: player.position,
  birthdate: player.birthdate,
  age: player.birthdate ? calculateAge(player.birthdate) : null,
  heightInches: player.heightInches,
  heightFormatted: player.heightInches ? formatHeight(player.heightInches) : null,
  weightLbs: player.weightLbs,
  weightFormatted: player.weightLbs ? formatWeight(player.weightLbs) : null,
  nationality: player.nationality,
  college: player.college,
  photoUrl: player.photoUrl,
  injuryStatus: player.injuryStatus,
  draftYear: player.draftYear,
  draftPickOverall: player.draftPickOverall,
  active: Boolean(player.active),
  apiPlayerId: player.apiPlayerId,
  team: {
    id: player.teamId,
    name: player.teamName,
    city: player.teamCity,
    abbreviation: player.teamAbbreviation,
    logoUrl: player.teamLogoUrl,
    conference: player.teamConference,
    division: player.teamDivision,
    league: {
      id: player.leagueId || 'NBA',
      name: player.leagueName || 'National Basketball Association',
      abbreviation: player.leagueAbbreviation || 'NBA',
      logoUrl: player.leagueLogoUrl || null,
      sport: player.leagueSport || 'basketball',
      level: player.leagueLevel || 'professional',
      isActive: Boolean(player.leagueIsActive !== undefined ? player.leagueIsActive : true)
    }
  },
  createdAt: player.createdAt,
  updatedAt: player.updatedAt
});

// GET /api/players - Get all players (optionally filtered by team or league)
router.get('/', async (req, res) => {
  try {
    const { teamId, leagueId, position } = req.query;
    
    let players;
    
    if (position) {
      players = await database.getPlayersByPosition(position, leagueId);
    } else {
      players = await database.getPlayers(teamId, leagueId);
    }
    
    // Transform data for API response
    const transformedPlayers = players.map(transformPlayer);
    
    res.json({
      success: true,
      data: transformedPlayers,
      count: transformedPlayers.length,
      filters: {
        teamId: teamId || null,
        leagueId: leagueId || null,
        position: position || null
      }
    });

  } catch (error) {
    console.error('Error fetching players:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/players/:id - Get specific player
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const player = await database.getPlayer(id);
    
    if (!player) {
      return res.status(404).json({
        success: false,
        message: 'Player not found'
      });
    }
    
    const transformedPlayer = transformPlayer(player);
    
    res.json({
      success: true,
      data: transformedPlayer
    });

  } catch (error) {
    console.error('Error fetching player:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/players/team/:teamId - Get team roster
router.get('/team/:teamId', async (req, res) => {
  try {
    const { teamId } = req.params;
    
    const players = await database.getTeamRoster(teamId);
    
    // Transform data for API response
    const transformedPlayers = players.map(transformPlayer);
    
    // Group by position for better organization
    const playersByPosition = transformedPlayers.reduce((acc, player) => {
      const position = player.position;
      if (!acc[position]) {
        acc[position] = [];
      }
      acc[position].push(player);
      return acc;
    }, {});
    
    res.json({
      success: true,
      data: transformedPlayers,
      dataByPosition: playersByPosition,
      count: transformedPlayers.length,
      teamId: teamId
    });

  } catch (error) {
    console.error('Error fetching team roster:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// POST /api/players - Create new player
router.post('/', async (req, res) => {
  try {
    const playerData = req.body;
    
    // Validate required fields
    const requiredFields = ['id', 'teamId', 'displayName', 'firstName', 'lastName'];
    const missingFields = requiredFields.filter(field => !playerData[field]);
    
    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
        missingFields: missingFields
      });
    }
    
    await database.savePlayer(playerData);
    
    // Fetch the created player to return
    const player = await database.getPlayer(playerData.id);
    const transformedPlayer = transformPlayer(player);
    
    res.status(201).json({
      success: true,
      data: transformedPlayer,
      message: 'Player created successfully'
    });

  } catch (error) {
    console.error('Error creating player:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// PUT /api/players/:id - Update player
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const playerData = req.body;
    
    // Ensure the ID matches the URL parameter
    playerData.id = id;
    
    await database.savePlayer(playerData);
    
    // Fetch the updated player to return
    const player = await database.getPlayer(id);
    const transformedPlayer = transformPlayer(player);
    
    res.json({
      success: true,
      data: transformedPlayer,
      message: 'Player updated successfully'
    });

  } catch (error) {
    console.error('Error updating player:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// DELETE /api/players/:id - Delete player (soft delete by setting active to false)
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get current player data
    const player = await database.getPlayer(id);
    
    if (!player) {
      return res.status(404).json({
        success: false,
        message: 'Player not found'
      });
    }
    
    // Soft delete by setting active to false
    const updatedPlayer = {
      ...player,
      active: false
    };
    
    await database.savePlayer(updatedPlayer);
    
    res.json({
      success: true,
      message: 'Player deactivated successfully'
    });

  } catch (error) {
    console.error('Error deleting player:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
