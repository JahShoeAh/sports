const express = require('express');
const router = express.Router();
const database = require('../services/database');
// Removed dataRefresh - no longer using external APIs

// GET /api/games - Get all games for a league
router.get('/', async (req, res) => {
  try {
    const { leagueId, season } = req.query;
    
    if (!leagueId) {
      return res.status(400).json({
        success: false,
        message: 'leagueId is required'
      });
    }

    const games = await database.getGames(leagueId, season);
    
    // Transform data to match iOS app expectations
    const transformedGames = games.map(game => ({
      id: game.id,
      homeTeam: {
        id: game.home_team_id,
        name: game.home_team_name,
        city: game.home_team_city,
        abbreviation: game.home_team_abbr,
        logoURL: game.home_team_logo,
        league: {
          id: game.league_id,
          name: 'NFL',
          abbreviation: 'NFL',
          logoURL: null,
          sport: 'football',
          level: 'professional',
          season: game.season,
          isActive: true
        },
        conference: null, // Will be populated from teams endpoint
        division: null,
        colors: null
      },
      awayTeam: {
        id: game.away_team_id,
        name: game.away_team_name,
        city: game.away_team_city,
        abbreviation: game.away_team_abbr,
        logoURL: game.away_team_logo,
        league: {
          id: game.league_id,
          name: 'NFL',
          abbreviation: 'NFL',
          logoURL: null,
          sport: 'football',
          level: 'professional',
          season: game.season,
          isActive: true
        },
        conference: null,
        division: null,
        colors: null
      },
      league: {
        id: game.league_id,
        name: 'NFL',
        abbreviation: 'NFL',
        logoURL: null,
        sport: 'football',
        level: 'professional',
        season: game.season,
        isActive: true
      },
      season: game.season,
      week: game.week,
      gameDate: game.game_date,
      gameTime: game.game_time,
      venue: game.venue,
      city: game.city,
      state: game.state,
      country: game.country,
      status: game.status,
      homeScore: game.home_score,
      awayScore: game.away_score,
      quarter: game.quarter,
      timeRemaining: game.time_remaining,
      isLive: game.is_live === 1,
      isCompleted: game.is_completed === 1,
      startingLineups: null,
      boxScore: null,
      gameStats: null
    }));

    res.json({
      success: true,
      data: transformedGames,
      count: transformedGames.length,
      leagueId: leagueId,
      season: season || 'all'
    });

  } catch (error) {
    console.error('Error fetching games:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/games/:id - Get specific game
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const games = await database.getGames('1'); // NFL league ID
    const game = games.find(g => g.id === id);
    
    if (!game) {
      return res.status(404).json({
        success: false,
        message: 'Game not found'
      });
    }

    // Transform single game (similar to above)
    const transformedGame = {
      id: game.id,
      homeTeam: {
        id: game.home_team_id,
        name: game.home_team_name,
        city: game.home_team_city,
        abbreviation: game.home_team_abbr,
        logoURL: game.home_team_logo,
        league: {
          id: game.league_id,
          name: 'NFL',
          abbreviation: 'NFL',
          logoURL: null,
          sport: 'football',
          level: 'professional',
          season: game.season,
          isActive: true
        },
        conference: null,
        division: null,
        colors: null
      },
      awayTeam: {
        id: game.away_team_id,
        name: game.away_team_name,
        city: game.away_team_city,
        abbreviation: game.away_team_abbr,
        logoURL: game.away_team_logo,
        league: {
          id: game.league_id,
          name: 'NFL',
          abbreviation: 'NFL',
          logoURL: null,
          sport: 'football',
          level: 'professional',
          season: game.season,
          isActive: true
        },
        conference: null,
        division: null,
        colors: null
      },
      league: {
        id: game.league_id,
        name: 'NFL',
        abbreviation: 'NFL',
        logoURL: null,
        sport: 'football',
        level: 'professional',
        season: game.season,
        isActive: true
      },
      season: game.season,
      week: game.week,
      gameDate: game.game_date,
      gameTime: game.game_time,
      venue: game.venue,
      city: game.city,
      state: game.state,
      country: game.country,
      status: game.status,
      homeScore: game.home_score,
      awayScore: game.away_score,
      quarter: game.quarter,
      timeRemaining: game.time_remaining,
      isLive: game.is_live === 1,
      isCompleted: game.is_completed === 1,
      startingLineups: null,
      boxScore: null,
      gameStats: null
    };

    res.json({
      success: true,
      data: transformedGame
    });

  } catch (error) {
    console.error('Error fetching game:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// POST /api/games/refresh - Data refresh removed (using static data)

module.exports = router;
