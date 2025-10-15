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
        id: game.homeTeamId,
        name: game.homeTeamName,
        city: game.homeTeamCity,
        abbreviation: game.homeTeamAbbr,
        logoURL: game.homeTeamLogo,
        league: {
          id: game.leagueId,
          name: game.leagueName || 'Unknown League',
          abbreviation: game.leagueAbbreviation || game.leagueId,
          logoURL: game.leagueLogoUrl,
          sport: game.leagueSport || 'unknown',
          level: game.leagueLevel || 'professional',
          isActive: Boolean(game.leagueIsActive)
        },
        conference: game.homeTeamConference,
        division: game.homeTeamDivision,
        colors: null,
      },
      awayTeam: {
        id: game.awayTeamId,
        name: game.awayTeamName,
        city: game.awayTeamCity,
        abbreviation: game.awayTeamAbbr,
        logoURL: game.awayTeamLogo,
        league: {
          id: game.leagueId,
          name: game.leagueName || 'Unknown League',
          abbreviation: game.leagueAbbreviation || game.leagueId,
          logoURL: game.leagueLogoUrl,
          sport: game.leagueSport || 'unknown',
          level: game.leagueLevel || 'professional',
          isActive: Boolean(game.leagueIsActive)
        },
        conference: game.awayTeamConference,
        division: game.awayTeamDivision,
        colors: null,
      },
      league: {
        id: game.leagueId,
        name: game.leagueName || 'Unknown League',
        abbreviation: game.leagueAbbreviation || game.leagueId,
        logoURL: game.leagueLogoUrl,
        sport: game.leagueSport || 'unknown',
        level: game.leagueLevel || 'professional',
        isActive: Boolean(game.leagueIsActive)
      },
      season: game.season,
      week: game.week,
      gameDate: game.gameDate, // Keep as date string for easier parsing
      gameTime: new Date(`${game.gameDate}T${game.gameTime}`).toISOString(), // Full datetime
      venue: game.venueId ? {
        id: game.venueId,
        name: game.venueName,
        city: game.venueCity,
        state: game.venueState,
        country: game.venueCountry,
        homeTeamId: game.venueHomeTeamId
      } : null,
      homeScore: game.homeScore,
      awayScore: game.awayScore,
      quarter: game.quarter,
      isLive: game.isLive === 1,
      isCompleted: game.isCompleted === 1,
      startingLineups: null,
      boxScore: game.boxScore ? JSON.parse(game.boxScore) : null
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
    const { leagueId } = req.query;
    const games = await database.getGames(leagueId || 'NBA'); // Use provided leagueId or default to NBA
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
        id: game.homeTeamId,
        name: game.homeTeamName,
        city: game.homeTeamCity,
        abbreviation: game.homeTeamAbbr,
        logoURL: game.homeTeamLogo,
        league: {
          id: game.leagueId,
          name: game.leagueName || 'Unknown League',
          abbreviation: game.leagueAbbreviation || game.leagueId,
          logoURL: game.leagueLogoUrl,
          sport: game.leagueSport || 'unknown',
          level: game.leagueLevel || 'professional',
          isActive: Boolean(game.leagueIsActive)
        },
        conference: game.homeTeamConference,
        division: game.homeTeamDivision,
        colors: null,
      },
      awayTeam: {
        id: game.awayTeamId,
        name: game.awayTeamName,
        city: game.awayTeamCity,
        abbreviation: game.awayTeamAbbr,
        logoURL: game.awayTeamLogo,
        league: {
          id: game.leagueId,
          name: game.leagueName || 'Unknown League',
          abbreviation: game.leagueAbbreviation || game.leagueId,
          logoURL: game.leagueLogoUrl,
          sport: game.leagueSport || 'unknown',
          level: game.leagueLevel || 'professional',
          isActive: Boolean(game.leagueIsActive)
        },
        conference: game.awayTeamConference,
        division: game.awayTeamDivision,
        colors: null,
      },
      league: {
        id: game.leagueId,
        name: game.leagueName || 'Unknown League',
        abbreviation: game.leagueAbbreviation || game.leagueId,
        logoURL: game.leagueLogoUrl,
        sport: game.leagueSport || 'unknown',
        level: game.leagueLevel || 'professional',
        isActive: Boolean(game.leagueIsActive)
      },
      season: game.season,
      week: game.week,
      gameDate: game.gameDate, // Keep as date string for easier parsing
      gameTime: new Date(`${game.gameDate}T${game.gameTime}`).toISOString(), // Full datetime
      venue: game.venueId ? {
        id: game.venueId,
        name: game.venueName,
        city: game.venueCity,
        state: game.venueState,
        country: game.venueCountry,
        homeTeamId: game.venueHomeTeamId
      } : null,
      homeScore: game.homeScore,
      awayScore: game.awayScore,
      quarter: game.quarter,
      isLive: game.isLive === 1,
      isCompleted: game.isCompleted === 1,
      startingLineups: null,
      boxScore: game.boxScore ? JSON.parse(game.boxScore) : null
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
