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

    const teams = await database.getTeamsWithLeague(leagueId);
    
    // Transform data to match iOS app expectations
    const transformedTeams = teams.map(team => ({
      id: team.id,
      name: team.name,
      city: team.city,
      abbreviation: team.abbreviation,
      logoURL: team.logoUrl,
      league: {
        id: team.leagueId,
        name: team.leagueName || 'Unknown League',
        abbreviation: team.leagueAbbreviation || team.leagueId,
        logoURL: team.leagueLogoUrl,
        sport: team.leagueSport || 'unknown',
        level: team.leagueLevel || 'professional',
        isActive: Boolean(team.leagueIsActive)
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

    const teams = await database.getTeamsWithLeague(leagueId);
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
      logoURL: team.logoUrl,
      league: {
        id: team.leagueId,
        name: team.leagueName || 'Unknown League',
        abbreviation: team.leagueAbbreviation || team.leagueId,
        logoURL: team.leagueLogoUrl,
        sport: team.leagueSport || 'unknown',
        level: team.leagueLevel || 'professional',
        isActive: Boolean(team.leagueIsActive)
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
