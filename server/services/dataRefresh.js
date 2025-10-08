const apiSports = require('./apiSports');
const database = require('./database');
const config = require('../config');

class DataRefreshService {
  constructor() {
    this.isRefreshing = false;
  }

  // Main refresh method for a specific league
  async refreshLeagueData(leagueId, season = '2023') {
    if (this.isRefreshing) {
      console.log('Data refresh already in progress, skipping...');
      return { success: false, message: 'Refresh already in progress' };
    }

    this.isRefreshing = true;
    console.log(`Starting data refresh for league ${leagueId}, season ${season}`);

    try {
      // Check if data is already fresh
      const isFresh = await database.isDataFresh(leagueId, config.dataRefresh.maxAge);
      if (isFresh) {
        console.log(`Data for league ${leagueId} is already fresh, skipping refresh`);
        return { success: true, message: 'Data is already fresh' };
      }

      // Clear old data for this league
      await database.clearLeagueData(leagueId);
      console.log(`Cleared old data for league ${leagueId}`);

      // Save league info
      const league = {
        id: leagueId,
        name: 'NFL',
        abbreviation: 'NFL',
        logoURL: null,
        sport: 'football',
        level: 'professional',
        season: season,
        isActive: true
      };
      await database.saveLeague(league);
      console.log(`Saved league info for ${league.name}`);

      // Fetch and save teams
      const teamsData = await apiSports.fetchNFLTeams();
      let teamsSaved = 0;
      
      for (const teamData of teamsData) {
        const team = {
          id: teamData.team.id.toString(),
          name: teamData.team.name,
          city: teamData.team.city || teamData.team.name,
          abbreviation: teamData.team.abbreviation || teamData.team.name,
          logoURL: teamData.team.logo,
          leagueId: leagueId,
          conference: teamData.team.conference,
          division: teamData.team.division
        };
        
        await database.saveTeam(team);
        teamsSaved++;
      }
      console.log(`Saved ${teamsSaved} teams for league ${leagueId}`);

      // Fetch and save games
      const gamesData = await apiSports.fetchNFLGames(season);
      let gamesSaved = 0;
      
      for (const gameData of gamesData) {
        // Validate and parse date
        let gameDate, gameTime;
        if (gameData.game.date) {
          const parsedDate = new Date(gameData.game.date);
          if (!isNaN(parsedDate.getTime())) {
            gameDate = parsedDate;
            gameTime = parsedDate;
          } else {
            console.warn(`Invalid date for game ${gameData.game.id}: ${gameData.game.date}`);
            gameDate = new Date(); // Use current date as fallback
            gameTime = new Date();
          }
        } else {
          console.warn(`No date for game ${gameData.game.id}`);
          gameDate = new Date(); // Use current date as fallback
          gameTime = new Date();
        }

        const game = {
          id: gameData.game.id.toString(),
          homeTeamId: gameData.teams.home.id.toString(),
          awayTeamId: gameData.teams.away.id.toString(),
          leagueId: leagueId,
          season: season,
          week: gameData.game.week,
          gameDate: gameDate,
          gameTime: gameTime,
          venueId: null, // API doesn't provide venue ID
          venue: gameData.game.venue?.name || 'Unknown',
          city: gameData.game.venue?.city || 'Unknown',
          state: gameData.game.venue?.state || 'Unknown',
          country: gameData.game.venue?.country || 'USA',
          status: gameData.game.status.short,
          homeScore: gameData.scores?.home.total || null,
          awayScore: gameData.scores?.away.total || null,
          quarter: gameData.scores?.home.quarter?.length || null,
          timeRemaining: gameData.game.status.timer,
          isLive: gameData.game.status.short === 'live',
          isCompleted: gameData.game.status.short === 'finished'
        };
        
        await database.saveGame(game);
        gamesSaved++;
      }
      console.log(`Saved ${gamesSaved} games for league ${leagueId}`);

      // Update data freshness
      await database.updateDataFreshness(leagueId, true);
      console.log(`Data refresh completed successfully for league ${leagueId}`);

      return {
        success: true,
        message: 'Data refreshed successfully',
        stats: {
          teams: teamsSaved,
          games: gamesSaved,
          league: leagueId
        }
      };

    } catch (error) {
      console.error(`Error refreshing data for league ${leagueId}:`, error);
      
      // Update data freshness with error
      await database.updateDataFreshness(leagueId, false, error.message);
      
      return {
        success: false,
        message: 'Data refresh failed',
        error: error.message
      };
    } finally {
      this.isRefreshing = false;
    }
  }

  // Refresh all supported leagues
  async refreshAllData() {
    console.log('Starting refresh for all leagues...');
    
    const results = [];
    const leagues = [
      { id: '1', name: 'NFL', season: '2023' }
      // Add more leagues here as needed
    ];

    for (const league of leagues) {
      try {
        const result = await this.refreshLeagueData(league.id, league.season);
        results.push({
          league: league.name,
          ...result
        });
      } catch (error) {
        results.push({
          league: league.name,
          success: false,
          message: 'Refresh failed',
          error: error.message
        });
      }
    }

    console.log('All league refreshes completed');
    return results;
  }

  // Force refresh (ignores freshness check)
  async forceRefreshLeagueData(leagueId, season = '2023') {
    console.log(`Force refreshing data for league ${leagueId}`);
    
    // Temporarily set a very short max age to force refresh
    const originalMaxAge = config.dataRefresh.maxAge;
    config.dataRefresh.maxAge = 0;
    
    try {
      const result = await this.refreshLeagueData(leagueId, season);
      return result;
    } finally {
      // Restore original max age
      config.dataRefresh.maxAge = originalMaxAge;
    }
  }

  // Get refresh status
  async getRefreshStatus() {
    const stats = await database.getStats();
    const isRefreshing = this.isRefreshing;
    
    return {
      isRefreshing,
      stats,
      lastRefresh: new Date().toISOString()
    };
  }

  // Test API connection
  async testApiConnection() {
    try {
      const result = await apiSports.testConnection();
      return result;
    } catch (error) {
      return {
        success: false,
        message: 'API connection test failed',
        error: error.message
      };
    }
  }
}

module.exports = new DataRefreshService();
