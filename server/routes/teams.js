const express = require('express');
const router = express.Router();
const database = require('../services/database');
const dataRefresh = require('../services/dataRefresh');

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
    
    // Transform data to match iOS app expectations
    const transformedTeams = teams.map(team => ({
      id: team.id,
      name: team.name,
      city: team.city,
      abbreviation: team.abbreviation,
      logoURL: team.logo_url,
      league: {
        id: team.league_id,
        name: 'NFL',
        abbreviation: 'NFL',
        logoURL: null,
        sport: 'football',
        level: 'professional',
        season: '2025',
        isActive: true
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

    // Transform single team
    const transformedTeam = {
      id: team.id,
      name: team.name,
      city: team.city,
      abbreviation: team.abbreviation,
      logoURL: team.logo_url,
      league: {
        id: team.league_id,
        name: 'NFL',
        abbreviation: 'NFL',
        logoURL: null,
        sport: 'football',
        level: 'professional',
        season: '2025',
        isActive: true
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

// POST /api/teams/refresh - Force refresh teams data
router.post('/refresh', async (req, res) => {
  try {
    const { leagueId = '1', season = '2025' } = req.body;
    
    const result = await dataRefresh.forceRefreshLeagueData(leagueId, season);
    
    res.json(result);

  } catch (error) {
    console.error('Error refreshing teams:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
