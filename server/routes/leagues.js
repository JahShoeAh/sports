const express = require('express');
const router = express.Router();
const database = require('../services/database');
// Removed dataRefresh - no longer using external APIs

// GET /api/leagues - Get all leagues
router.get('/', async (req, res) => {
  try {
    const leagues = await database.getLeagues();
    
    // Transform data to match iOS app expectations
    const transformedLeagues = leagues.map(league => ({
      id: league.id,
      name: league.name,
      abbreviation: league.abbreviation,
      logoURL: league.logo_url,
      sport: league.sport,
      level: league.level,
      isActive: league.is_active === 1
    }));

    res.json({
      success: true,
      data: transformedLeagues,
      count: transformedLeagues.length
    });

  } catch (error) {
    console.error('Error fetching leagues:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/leagues/:id - Get specific league
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const leagues = await database.getLeagues();
    const league = leagues.find(l => l.id === id);
    
    if (!league) {
      return res.status(404).json({
        success: false,
        message: 'League not found'
      });
    }

    // Transform single league
    const transformedLeague = {
      id: league.id,
      name: league.name,
      abbreviation: league.abbreviation,
      logoURL: league.logo_url,
      sport: league.sport,
      level: league.level,
      isActive: league.is_active === 1
    };

    res.json({
      success: true,
      data: transformedLeague
    });

  } catch (error) {
    console.error('Error fetching league:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Data refresh endpoints removed - using static data only

module.exports = router;
