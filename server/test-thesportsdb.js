const axios = require('axios');

// TheSportsDB API v1 Configuration
const API_BASE_URL = 'https://www.thesportsdb.com/api/v1/json';
const FREE_API_KEY = '123'; // Free API key from documentation

// Rate limiting helper
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class TheSportsDBTester {
  constructor() {
    this.baseUrl = `${API_BASE_URL}/${FREE_API_KEY}`;
    this.requestCount = 0;
    this.maxRequestsPerMinute = 30; // Free tier limit
  }

  async makeRequest(endpoint, params = {}) {
    // Rate limiting - wait if we've made too many requests
    if (this.requestCount >= this.maxRequestsPerMinute) {
      console.log('⏳ Rate limit reached, waiting 60 seconds...');
      await delay(60000);
      this.requestCount = 0;
    }

    try {
      const url = `${this.baseUrl}${endpoint}`;
      console.log(`🌐 Making request to: ${url}`);
      console.log(`📊 Parameters:`, params);
      
      const response = await axios.get(url, { params });
      this.requestCount++;
      
      console.log(`✅ Request successful (${this.requestCount}/${this.maxRequestsPerMinute})`);
      return response.data;
    } catch (error) {
      console.error(`❌ Request failed:`, error.message);
      if (error.response) {
        console.error(`   Status: ${error.response.status}`);
        console.error(`   Data:`, error.response.data);
      }
      throw error;
    }
  }

  // Test 1: Search for NFL teams
  async testSearchNFLTeams() {
    console.log('\n🏈 === TEST 1: Search NFL Teams ===');
    
    try {
      // Search for NFL teams by name
      const teams = await this.makeRequest('/searchteams.php', { t: 'NFL' });
      
      console.log(`📊 Found ${teams.teams ? teams.teams.length : 0} teams`);
      
      if (teams.teams && teams.teams.length > 0) {
        console.log('\n📋 Sample teams:');
        teams.teams.slice(0, 5).forEach((team, index) => {
          console.log(`   ${index + 1}. ${team.strTeam} (${team.strLeague})`);
          console.log(`      ID: ${team.idTeam}`);
          console.log(`      Stadium: ${team.strStadium}`);
          console.log(`      Website: ${team.strWebsite}`);
          console.log(`      Badge: ${team.strTeamBadge}`);
        });
      }
      
      return teams;
    } catch (error) {
      console.error('❌ Failed to search NFL teams:', error.message);
      return null;
    }
  }

  // Test 2: Get all NFL teams by league ID
  async testGetNFLTeamsByLeague() {
    console.log('\n🏈 === TEST 2: Get NFL Teams by League ID ===');
    
    try {
      // NFL league ID is typically 4391 based on common sports APIs
      const teams = await this.makeRequest('/lookupteam.php', { id: '4391' });
      
      console.log(`📊 Found ${teams.teams ? teams.teams.length : 0} teams`);
      
      if (teams.teams && teams.teams.length > 0) {
        console.log('\n📋 NFL Teams:');
        teams.teams.forEach((team, index) => {
          console.log(`   ${index + 1}. ${team.strTeam} (${team.strAlternate})`);
          console.log(`      ID: ${team.idTeam}`);
          console.log(`      League: ${team.strLeague}`);
          console.log(`      Stadium: ${team.strStadium}`);
          console.log(`      Founded: ${team.intFormedYear}`);
          console.log(`      Badge: ${team.strTeamBadge}`);
        });
      }
      
      return teams;
    } catch (error) {
      console.error('❌ Failed to get NFL teams by league:', error.message);
      return null;
    }
  }

  // Test 3: Search for NFL games/events
  async testSearchNFLGames() {
    console.log('\n🏈 === TEST 3: Search NFL Games/Events ===');
    
    try {
      // Search for NFL events
      const events = await this.makeRequest('/searchevents.php', { e: 'NFL' });
      
      console.log(`📊 Found ${events.event ? events.event.length : 0} events`);
      
      if (events.event && events.event.length > 0) {
        console.log('\n📋 Sample events:');
        events.event.slice(0, 5).forEach((event, index) => {
          console.log(`   ${index + 1}. ${event.strEvent}`);
          console.log(`      Date: ${event.dateEvent}`);
          console.log(`      Time: ${event.strTime}`);
          console.log(`      League: ${event.strLeague}`);
          console.log(`      Season: ${event.strSeason}`);
          console.log(`      Home: ${event.strHomeTeam}`);
          console.log(`      Away: ${event.strAwayTeam}`);
        });
      }
      
      return events;
    } catch (error) {
      console.error('❌ Failed to search NFL events:', error.message);
      return null;
    }
  }

  // Test 4: Get NFL games for 2025 season
  async testGetNFLGames2025() {
    console.log('\n🏈 === TEST 4: Get NFL Games for 2025 Season ===');
    
    try {
      // Search for NFL events in 2025 season
      const events = await this.makeRequest('/searchevents.php', { 
        e: 'NFL',
        s: '2025-2026' // Season format
      });
      
      console.log(`📊 Found ${events.event ? events.event.length : 0} events for 2025-2026 season`);
      
      if (events.event && events.event.length > 0) {
        console.log('\n📋 2025-2026 NFL Season Events:');
        events.event.slice(0, 10).forEach((event, index) => {
          console.log(`   ${index + 1}. ${event.strEvent}`);
          console.log(`      Date: ${event.dateEvent}`);
          console.log(`      Time: ${event.strTime}`);
          console.log(`      Home: ${event.strHomeTeam}`);
          console.log(`      Away: ${event.strAwayTeam}`);
          console.log(`      Venue: ${event.strVenue}`);
          console.log(`      Status: ${event.strStatus}`);
        });
      }
      
      return events;
    } catch (error) {
      console.error('❌ Failed to get NFL games for 2025:', error.message);
      return null;
    }
  }

  // Test 5: Get all leagues to find NFL
  async testGetAllLeagues() {
    console.log('\n🏈 === TEST 5: Get All Leagues (Find NFL) ===');
    
    try {
      const leagues = await this.makeRequest('/all_leagues.php');
      
      console.log(`📊 Found ${leagues.leagues ? leagues.leagues.length : 0} leagues`);
      
      if (leagues.leagues && leagues.leagues.length > 0) {
        // Filter for NFL-related leagues
        const nflLeagues = leagues.leagues.filter(league => 
          league.strLeague && league.strLeague.toLowerCase().includes('nfl')
        );
        
        console.log(`\n🏈 Found ${nflLeagues.length} NFL-related leagues:`);
        nflLeagues.forEach((league, index) => {
          console.log(`   ${index + 1}. ${league.strLeague}`);
          console.log(`      ID: ${league.idLeague}`);
          console.log(`      Sport: ${league.strSport}`);
          console.log(`      Country: ${league.strCountry}`);
        });
        
        // Also show some other popular leagues for reference
        console.log('\n📋 Other popular leagues:');
        leagues.leagues.slice(0, 10).forEach((league, index) => {
          console.log(`   ${index + 1}. ${league.strLeague} (${league.strSport}) - ID: ${league.idLeague}`);
        });
      }
      
      return leagues;
    } catch (error) {
      console.error('❌ Failed to get all leagues:', error.message);
      return null;
    }
  }

  // Test 6: Get events by date (recent NFL games)
  async testGetEventsByDate() {
    console.log('\n🏈 === TEST 6: Get Recent NFL Events by Date ===');
    
    try {
      // Get events from a recent date (you can modify this)
      const today = new Date();
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      const dateStr = yesterday.toISOString().split('T')[0]; // YYYY-MM-DD format
      
      console.log(`📅 Searching for events on: ${dateStr}`);
      
      const events = await this.makeRequest('/eventsday.php', { 
        d: dateStr,
        s: 'American Football' // Sport filter
      });
      
      console.log(`📊 Found ${events.events ? events.events.length : 0} events on ${dateStr}`);
      
      if (events.events && events.events.length > 0) {
        console.log('\n📋 Events:');
        events.events.forEach((event, index) => {
          console.log(`   ${index + 1}. ${event.strEvent}`);
          console.log(`      League: ${event.strLeague}`);
          console.log(`      Home: ${event.strHomeTeam}`);
          console.log(`      Away: ${event.strAwayTeam}`);
          console.log(`      Score: ${event.intHomeScore} - ${event.intAwayScore}`);
        });
      }
      
      return events;
    } catch (error) {
      console.error('❌ Failed to get events by date:', error.message);
      return null;
    }
  }

  // Run all tests
  async runAllTests() {
    console.log('🚀 Starting TheSportsDB API v1 Tests');
    console.log('=====================================');
    console.log(`📡 Base URL: ${this.baseUrl}`);
    console.log(`⏱️  Rate Limit: ${this.maxRequestsPerMinute} requests per minute`);
    
    const results = {};
    
    try {
      // Run tests with delays to respect rate limits
      results.leagues = await this.testGetAllLeagues();
      await delay(2000); // 2 second delay between requests
      
      results.teamsSearch = await this.testSearchNFLTeams();
      await delay(2000);
      
      results.teamsLeague = await this.testGetNFLTeamsByLeague();
      await delay(2000);
      
      results.eventsSearch = await this.testSearchNFLGames();
      await delay(2000);
      
      results.events2025 = await this.testGetNFLGames2025();
      await delay(2000);
      
      results.eventsByDate = await this.testGetEventsByDate();
      
      console.log('\n✅ All tests completed!');
      console.log('📊 Summary:');
      console.log(`   - Leagues found: ${results.leagues?.leagues?.length || 0}`);
      console.log(`   - Teams (search): ${results.teamsSearch?.teams?.length || 0}`);
      console.log(`   - Teams (league): ${results.teamsLeague?.teams?.length || 0}`);
      console.log(`   - Events (search): ${results.eventsSearch?.event?.length || 0}`);
      console.log(`   - Events (2025): ${results.events2025?.event?.length || 0}`);
      console.log(`   - Events (by date): ${results.eventsByDate?.events?.length || 0}`);
      
    } catch (error) {
      console.error('❌ Test suite failed:', error.message);
    }
    
    return results;
  }
}

// Run the tests if this file is executed directly
if (require.main === module) {
  const tester = new TheSportsDBTester();
  tester.runAllTests().catch(console.error);
}

module.exports = TheSportsDBTester;
