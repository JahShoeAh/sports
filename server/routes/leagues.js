const express = require('express');
const router = express.Router();
const database = require('../services/database');
const dataRefresh = require('../services/dataRefresh');

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
      season: league.season,
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
      season: league.season,
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

// GET /api/leagues/:id/status - Get league data freshness status
router.get('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const freshness = await database.getDataFreshness(id);
    const isFresh = await database.isDataFresh(id);
    
    res.json({
      success: true,
      data: {
        leagueId: id,
        isFresh: isFresh,
        lastUpdated: freshness?.last_updated,
        lastSuccessfulFetch: freshness?.last_successful_fetch,
        fetchAttempts: freshness?.fetch_attempts,
        lastError: freshness?.last_error
      }
    });

  } catch (error) {
    console.error('Error fetching league status:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// POST /api/leagues/:id/refresh - Force refresh league data
router.post('/:id/refresh', async (req, res) => {
  try {
    const { id } = req.params;
    const { season = '2023' } = req.body;
    
    const result = await dataRefresh.forceRefreshLeagueData(id, season);
    
    res.json(result);

  } catch (error) {
    console.error('Error refreshing league:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
