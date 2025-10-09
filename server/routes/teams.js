const express = require('express');
const router = express.Router();
const database = require('../services/database');
// Removed dataRefresh - no longer using external APIs

// GET /api/teams - Get all teams for a league
router.get('/', async (req, res) => {
  try {
    const { leagueId } = req.query;
    
    if (!leagueId) {
      return res.status(400).json({
        success: false,
        message: 'leagueId is required'
      });
    }

    const teams = await database.getTeams(leagueId);
    
    // Get league info for proper transformation
    const leagueInfo = await database.getLeague(leagueId);
    
    // Transform data to match iOS app expectations
    const transformedTeams = teams.map(team => ({
      id: team.id,
      name: team.name,
      city: team.city,
      abbreviation: team.abbreviation,
      logoURL: team.logo_url,
      league: {
        id: team.league_id,
        name: leagueInfo ? leagueInfo.name : team.league_id,
        abbreviation: leagueInfo ? leagueInfo.abbreviation : team.league_id,
        logoURL: null,
        sport: leagueInfo ? leagueInfo.sport : 'unknown',
        level: leagueInfo ? leagueInfo.level : 'professional',
        season: leagueInfo ? leagueInfo.season : '2024-25',
        isActive: leagueInfo ? leagueInfo.is_active : true
      },
      conference: team.conference,
      division: team.division,
      colors: null
    }));

    // Group teams by conference
    const teamsByConference = transformedTeams.reduce((acc, team) => {
      const conference = team.conference || 'Other';
      if (!acc[conference]) {
        acc[conference] = [];
      }
      acc[conference].push(team);
      return acc;
    }, {});

    res.json({
      success: true,
      data: transformedTeams,
      dataByConference: teamsByConference,
      count: transformedTeams.length,
      leagueId: leagueId
    });

  } catch (error) {
    console.error('Error fetching teams:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/teams/:id - Get specific team
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { leagueId } = req.query;
    
    if (!leagueId) {
      return res.status(400).json({
        success: false,
        message: 'leagueId is required'
      });
    }

    const teams = await database.getTeams(leagueId);
    const team = teams.find(t => t.id === id);
    
    if (!team) {
      return res.status(404).json({
        success: false,
        message: 'Team not found'
      });
    }

    // Get league info for proper transformation
    const leagueInfo = await database.getLeague(leagueId);
    
    // Transform single team
    const transformedTeam = {
      id: team.id,
      name: team.name,
      city: team.city,
      abbreviation: team.abbreviation,
      logoURL: team.logo_url,
      league: {
        id: team.league_id,
        name: leagueInfo ? leagueInfo.name : team.league_id,
        abbreviation: leagueInfo ? leagueInfo.abbreviation : team.league_id,
        logoURL: null,
        sport: leagueInfo ? leagueInfo.sport : 'unknown',
        level: leagueInfo ? leagueInfo.level : 'professional',
        season: leagueInfo ? leagueInfo.season : '2024-25',
        isActive: leagueInfo ? leagueInfo.is_active : true
      },
      conference: team.conference,
      division: team.division,
      colors: null
    };

    res.json({
      success: true,
      data: transformedTeam
    });

  } catch (error) {
    console.error('Error fetching team:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// POST /api/teams/refresh - Data refresh removed (using static data)

module.exports = router;
