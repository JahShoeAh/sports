const axios = require('axios');
const fs = require('fs');

// TheSportsDB API v1 Configuration
const API_BASE_URL = 'https://www.thesportsdb.com/api/v1/json';
const FREE_API_KEY = '123';

class TheSportsDBComprehensiveTester {
  constructor() {
    this.baseUrl = `${API_BASE_URL}/${FREE_API_KEY}`;
    this.requestCount = 0;
    this.maxRequestsPerMinute = 30;
    this.results = {
      timestamp: new Date().toISOString(),
      apiInfo: {
        baseUrl: this.baseUrl,
        rateLimit: this.maxRequestsPerMinute,
        version: 'v1'
      },
      data: {}
    };
  }

  async makeRequest(endpoint, params = {}) {
    if (this.requestCount >= this.maxRequestsPerMinute) {
      console.log('⏳ Rate limit reached, waiting 60 seconds...');
      await new Promise(resolve => setTimeout(resolve, 60000));
      this.requestCount = 0;
    }

    try {
      const url = `${this.baseUrl}${endpoint}`;
      console.log(`🌐 ${url}`, params);
      
      const response = await axios.get(url, { params });
      this.requestCount++;
      
      console.log(`✅ Success (${this.requestCount}/${this.maxRequestsPerMinute})`);
      return response.data;
    } catch (error) {
      console.error(`❌ Failed:`, error.message);
      if (error.response) {
        console.error(`   Status: ${error.response.status}`);
        console.error(`   Data:`, error.response.data);
      }
      throw error;
    }
  }

  async delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // Test API connectivity and basic functionality
  async testAPIConnectivity() {
    console.log('\n🔌 === API Connectivity Test ===');
    
    try {
      // Test basic API response
      const response = await this.makeRequest('/all_leagues.php');
      
      if (response.leagues) {
        console.log(`✅ API is working! Found ${response.leagues.length} leagues`);
        this.results.data.connectivity = {
          status: 'success',
          leaguesCount: response.leagues.length,
          sampleLeagues: response.leagues.slice(0, 5).map(league => ({
            id: league.idLeague,
            name: league.strLeague,
            sport: league.strSport,
            country: league.strCountry
          }))
        };
        return true;
      } else {
        console.log('❌ API response format unexpected');
        this.results.data.connectivity = { status: 'failed', error: 'Unexpected response format' };
        return false;
      }
    } catch (error) {
      console.error('❌ API connectivity test failed:', error.message);
      this.results.data.connectivity = { status: 'failed', error: error.message };
      return false;
    }
  }

  // Find and analyze NFL-related data
  async analyzeNFLData() {
    console.log('\n🏈 === NFL Data Analysis ===');
    
    try {
      // Get all leagues to find NFL
      const leagues = await this.makeRequest('/all_leagues.php');
      await this.delay(2000);
      
      if (!leagues.leagues) {
        throw new Error('No leagues data received');
      }
      
      // Find NFL-related leagues
      const nflLeagues = leagues.leagues.filter(league => 
        league.strLeague && (
          league.strLeague.toLowerCase().includes('nfl') ||
          league.strLeague.toLowerCase().includes('american football') ||
          league.strLeague.toLowerCase().includes('national football')
        )
      );
      
      console.log(`📊 Found ${nflLeagues.length} NFL-related leagues`);
      
      this.results.data.nflLeagues = nflLeagues.map(league => ({
        id: league.idLeague,
        name: league.strLeague,
        sport: league.strSport,
        country: league.strCountry,
        description: league.strDescription
      }));
      
      // Try to get teams for each NFL league
      const nflTeams = [];
      for (const league of nflLeagues) {
        try {
          console.log(`\n🔍 Getting teams for league: ${league.strLeague} (ID: ${league.idLeague})`);
          
          const teams = await this.makeRequest('/lookupteam.php', { id: league.idLeague });
          await this.delay(2000);
          
          if (teams.teams && teams.teams.length > 0) {
            console.log(`   Found ${teams.teams.length} teams`);
            nflTeams.push(...teams.teams.map(team => ({
              id: team.idTeam,
              name: team.strTeam,
              alternate: team.strAlternate,
              league: team.strLeague,
              stadium: team.strStadium,
              founded: team.intFormedYear,
              badge: team.strTeamBadge,
              website: team.strWebsite,
              description: team.strDescription
            })));
          }
        } catch (error) {
          console.log(`   ❌ Failed to get teams for ${league.strLeague}:`, error.message);
        }
      }
      
      // Remove duplicates
      const uniqueTeams = nflTeams.filter((team, index, self) => 
        index === self.findIndex(t => t.id === team.id)
      );
      
      console.log(`\n📊 Total unique NFL teams: ${uniqueTeams.length}`);
      this.results.data.nflTeams = uniqueTeams;
      
      return { leagues: nflLeagues, teams: uniqueTeams };
    } catch (error) {
      console.error('❌ NFL data analysis failed:', error.message);
      this.results.data.nflAnalysis = { status: 'failed', error: error.message };
      return null;
    }
  }

  // Get NFL games for 2025 season
  async getNFLGames2025() {
    console.log('\n🏈 === NFL 2025 Season Games ===');
    
    try {
      const seasonVariations = ['2025', '2025-2026', '2025-26', '2025 Season'];
      let allEvents = [];
      
      for (const season of seasonVariations) {
        try {
          console.log(`\n🔍 Searching for season: ${season}`);
          
          // Search with NFL filter
          const nflEvents = await this.makeRequest('/searchevents.php', { 
            e: 'NFL',
            s: season
          });
          await this.delay(2000);
          
          if (nflEvents.event) {
            console.log(`   Found ${nflEvents.event.length} NFL events for ${season}`);
            allEvents.push(...nflEvents.event);
          }
          
          // Search without event filter but with season
          const seasonEvents = await this.makeRequest('/searchevents.php', { 
            s: season
          });
          await this.delay(2000);
          
          if (seasonEvents.event) {
            const filteredNFL = seasonEvents.event.filter(event => 
              event.strLeague && event.strLeague.toLowerCase().includes('nfl')
            );
            console.log(`   Found ${filteredNFL.length} additional NFL events for ${season}`);
            allEvents.push(...filteredNFL);
          }
          
        } catch (error) {
          console.log(`   ❌ Season ${season} search failed:`, error.message);
        }
      }
      
      // Remove duplicates and format
      const uniqueEvents = allEvents.filter((event, index, self) => 
        index === self.findIndex(e => e.idEvent === event.idEvent)
      );
      
      const formattedEvents = uniqueEvents.map(event => ({
        id: event.idEvent,
        name: event.strEvent,
        date: event.dateEvent,
        time: event.strTime,
        homeTeam: event.strHomeTeam,
        awayTeam: event.strAwayTeam,
        venue: event.strVenue,
        status: event.strStatus,
        season: event.strSeason,
        league: event.strLeague,
        homeScore: event.intHomeScore,
        awayScore: event.intAwayScore,
        description: event.strDescription
      }));
      
      console.log(`\n📊 Total unique NFL events for 2025: ${formattedEvents.length}`);
      this.results.data.nflGames2025 = formattedEvents;
      
      return formattedEvents;
    } catch (error) {
      console.error('❌ Failed to get NFL games for 2025:', error.message);
      this.results.data.nflGames2025 = { status: 'failed', error: error.message };
      return [];
    }
  }

  // Get recent and upcoming NFL games
  async getRecentAndUpcomingGames() {
    console.log('\n🏈 === Recent & Upcoming NFL Games ===');
    
    try {
      const today = new Date();
      const dates = [];
      
      // Get past 3 days and next 7 days
      for (let i = -3; i <= 7; i++) {
        const date = new Date(today);
        date.setDate(date.getDate() + i);
        dates.push(date.toISOString().split('T')[0]);
      }
      
      let allEvents = [];
      
      for (const date of dates) {
        try {
          console.log(`\n🔍 Searching for events on: ${date}`);
          
          const events = await this.makeRequest('/eventsday.php', { 
            d: date,
            s: 'American Football'
          });
          await this.delay(2000);
          
          if (events.events) {
            const nflEvents = events.events.filter(event => 
              event.strLeague && event.strLeague.toLowerCase().includes('nfl')
            );
            console.log(`   Found ${nflEvents.length} NFL events on ${date}`);
            allEvents.push(...nflEvents);
          }
        } catch (error) {
          console.log(`   ❌ Date ${date} search failed:`, error.message);
        }
      }
      
      // Format and categorize events
      const formattedEvents = allEvents.map(event => ({
        id: event.idEvent,
        name: event.strEvent,
        date: event.dateEvent,
        time: event.strTime,
        homeTeam: event.strHomeTeam,
        awayTeam: event.strAwayTeam,
        venue: event.strVenue,
        status: event.strStatus,
        homeScore: event.intHomeScore,
        awayScore: event.intAwayScore,
        isUpcoming: new Date(event.dateEvent) > today
      }));
      
      const upcoming = formattedEvents.filter(event => event.isUpcoming);
      const recent = formattedEvents.filter(event => !event.isUpcoming);
      
      console.log(`\n📊 Found ${recent.length} recent and ${upcoming.length} upcoming NFL games`);
      
      this.results.data.recentGames = recent;
      this.results.data.upcomingGames = upcoming;
      
      return { recent, upcoming };
    } catch (error) {
      console.error('❌ Failed to get recent/upcoming games:', error.message);
      this.results.data.recentUpcomingGames = { status: 'failed', error: error.message };
      return { recent: [], upcoming: [] };
    }
  }

  // Test different API endpoints
  async testAPIEndpoints() {
    console.log('\n🔧 === API Endpoints Test ===');
    
    const endpoints = [
      { name: 'All Leagues', endpoint: '/all_leagues.php', params: {} },
      { name: 'All Sports', endpoint: '/all_sports.php', params: {} },
      { name: 'All Countries', endpoint: '/all_countries.php', params: {} },
      { name: 'Search Teams (NFL)', endpoint: '/searchteams.php', params: { t: 'NFL' } },
      { name: 'Search Events (NFL)', endpoint: '/searchevents.php', params: { e: 'NFL' } }
    ];
    
    const endpointResults = {};
    
    for (const test of endpoints) {
      try {
        console.log(`\n🔍 Testing: ${test.name}`);
        const result = await this.makeRequest(test.endpoint, test.params);
        await this.delay(2000);
        
        const key = Object.keys(result)[0]; // Get the main data key
        const count = result[key] ? result[key].length : 0;
        
        console.log(`   ✅ Success: ${count} items returned`);
        endpointResults[test.name] = {
          status: 'success',
          count: count,
          sampleData: result[key] ? result[key].slice(0, 2) : []
        };
      } catch (error) {
        console.log(`   ❌ Failed: ${error.message}`);
        endpointResults[test.name] = {
          status: 'failed',
          error: error.message
        };
      }
    }
    
    this.results.data.endpointTests = endpointResults;
    return endpointResults;
  }

  // Save results to file
  saveResults() {
    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `thesportsdb-test-results-${timestamp}.json`;
    
    try {
      fs.writeFileSync(filename, JSON.stringify(this.results, null, 2));
      console.log(`\n💾 Results saved to: ${filename}`);
      return filename;
    } catch (error) {
      console.error('❌ Failed to save results:', error.message);
      return null;
    }
  }

  // Run comprehensive test suite
  async runComprehensiveTest() {
    console.log('🚀 Starting TheSportsDB API v1 Comprehensive Test');
    console.log('================================================');
    console.log(`📡 Base URL: ${this.baseUrl}`);
    console.log(`⏱️  Rate Limit: ${this.maxRequestsPerMinute} requests per minute`);
    console.log(`🕐 Started at: ${new Date().toISOString()}`);
    
    try {
      // Test 1: API Connectivity
      const isConnected = await this.testAPIConnectivity();
      if (!isConnected) {
        console.log('❌ API connectivity failed, stopping tests');
        return this.results;
      }
      
      // Test 2: API Endpoints
      await this.testAPIEndpoints();
      
      // Test 3: NFL Data Analysis
      await this.analyzeNFLData();
      
      // Test 4: NFL 2025 Games
      await this.getNFLGames2025();
      
      // Test 5: Recent & Upcoming Games
      await this.getRecentAndUpcomingGames();
      
      // Save results
      const filename = this.saveResults();
      
      console.log('\n✅ Comprehensive Test Completed!');
      console.log('📊 Final Summary:');
      console.log(`   - API Status: ${this.results.data.connectivity?.status || 'Unknown'}`);
      console.log(`   - NFL Leagues: ${this.results.data.nflLeagues?.length || 0}`);
      console.log(`   - NFL Teams: ${this.results.data.nflTeams?.length || 0}`);
      console.log(`   - 2025 Games: ${this.results.data.nflGames2025?.length || 0}`);
      console.log(`   - Recent Games: ${this.results.data.recentGames?.length || 0}`);
      console.log(`   - Upcoming Games: ${this.results.data.upcomingGames?.length || 0}`);
      console.log(`   - Results File: ${filename || 'Failed to save'}`);
      
    } catch (error) {
      console.error('❌ Comprehensive test failed:', error.message);
      this.results.error = error.message;
    }
    
    return this.results;
  }
}

// Run the comprehensive test if this file is executed directly
if (require.main === module) {
  const tester = new TheSportsDBComprehensiveTester();
  tester.runComprehensiveTest().catch(console.error);
}

module.exports = TheSportsDBComprehensiveTester;
