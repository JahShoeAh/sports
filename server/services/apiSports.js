const axios = require('axios');
const config = require('../config');

class ApiSportsService {
  constructor() {
    this.baseURL = config.apiSportsBaseUrl;
    this.apiKey = config.apiSportsKey;
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        'X-RapidAPI-Key': this.apiKey,
        'X-RapidAPI-Host': 'v1.american-football.api-sports.io',
        'Accept': 'application/json'
      },
      timeout: 30000 // 30 seconds
    });
  }

  // Fetch NFL teams
  async fetchNFLTeams() {
    try {
      console.log('Fetching NFL teams...');
      
      const response = await this.client.get('/teams', {
        params: {
          league: '1' // NFL league ID - teams don't need season parameter
        }
      });

      if (response.data && response.data.response) {
        console.log(`Successfully fetched ${response.data.response.length} NFL teams`);
        return response.data.response;
      } else {
        console.log('API Response:', JSON.stringify(response.data, null, 2));
        throw new Error('Invalid response format from API-Sports');
      }
    } catch (error) {
      console.error('Error fetching NFL teams:', error.message);
      throw error;
    }
  }

  // Fetch NFL games
  async fetchNFLGames(season = '2023', week = null) {
    try {
      console.log(`Fetching NFL games for season ${season}${week ? `, week ${week}` : ''}...`);
      
      const params = {
        league: '1', // NFL league ID
        season: season
      };

      if (week) {
        params.week = week;
      }

      const response = await this.client.get('/games', {
        params: params
      });

      if (response.data && response.data.response) {
        console.log(`Successfully fetched ${response.data.response.length} NFL games`);
        return response.data.response;
      } else {
        throw new Error('Invalid response format from API-Sports');
      }
    } catch (error) {
      console.error('Error fetching NFL games:', error.message);
      throw error;
    }
  }

  // Fetch NFL players (for future use)
  async fetchNFLPlayers(teamId = null, season = '2023') {
    try {
      console.log(`Fetching NFL players${teamId ? ` for team ${teamId}` : ''}...`);
      
      const params = {
        league: '1', // NFL league ID
        season: season
      };

      if (teamId) {
        params.team = teamId;
      }

      const response = await this.client.get('/players', {
        params: params
      });

      if (response.data && response.data.response) {
        console.log(`Successfully fetched ${response.data.response.length} NFL players`);
        return response.data.response;
      } else {
        throw new Error('Invalid response format from API-Sports');
      }
    } catch (error) {
      console.error('Error fetching NFL players:', error.message);
      throw error;
    }
  }

  // Test API connection
  async testConnection() {
    try {
      const response = await this.client.get('/status');
      return {
        success: true,
        message: 'API connection successful',
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        message: 'API connection failed',
        error: error.message
      };
    }
  }

  // Get API usage statistics
  async getUsageStats() {
    try {
      const response = await this.client.get('/status');
      return response.data;
    } catch (error) {
      console.error('Error fetching API usage stats:', error.message);
      throw error;
    }
  }
}

module.exports = new ApiSportsService();
