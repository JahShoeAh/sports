const axios = require('axios');

// TheSportsDB API v1 Configuration
const API_BASE_URL = 'https://www.thesportsdb.com/api/v1/json';
const FREE_API_KEY = '123';

class NFLDataFetcher {
  constructor() {
    this.baseUrl = `${API_BASE_URL}/${FREE_API_KEY}`;
    this.requestCount = 0;
    this.maxRequestsPerMinute = 30;
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
      }
      throw error;
    }
  }

  // Find NFL league ID
  async findNFLLeagueId() {
    console.log('\n🔍 Finding NFL League ID...');
    
    try {
      const leagues = await this.makeRequest('/all_leagues.php');
      
      if (leagues.leagues) {
        const nflLeagues = leagues.leagues.filter(league => 
          league.strLeague && (
            league.strLeague.toLowerCase().includes('nfl') ||
            league.strLeague.toLowerCase().includes('american football') ||
            league.strLeague.toLowerCase().includes('national football')
          )
        );
        
        console.log(`📊 Found ${nflLeagues.length} NFL-related leagues:`);
        nflLeagues.forEach((league, index) => {
          console.log(`   ${index + 1}. ${league.strLeague} (ID: ${league.idLeague})`);
          console.log(`      Sport: ${league.strSport}, Country: ${league.strCountry}`);
        });
        
        return nflLeagues.length > 0 ? nflLeagues[0].idLeague : null;
      }
      
      return null;
    } catch (error) {
      console.error('❌ Failed to find NFL league ID:', error.message);
      return null;
    }
  }

  // Get all NFL teams
  async getAllNFLTeams() {
    console.log('\n🏈 Fetching All NFL Teams...');
    
    try {
      // Try different approaches to get NFL teams
      const approaches = [
        { name: 'Search by "NFL"', params: { t: 'NFL' } },
        { name: 'Search by "American Football"', params: { t: 'American Football' } },
        { name: 'Search by "Football"', params: { t: 'Football' } }
      ];
      
      let allTeams = [];
      
      for (const approach of approaches) {
        try {
          console.log(`\n🔍 Trying: ${approach.name}`);
          const result = await this.makeRequest('/searchteams.php', approach.params);
          
          if (result.teams) {
            // Filter for NFL teams specifically
            const nflTeams = result.teams.filter(team => 
              team.strLeague && team.strLeague.toLowerCase().includes('nfl')
            );
            
            console.log(`   Found ${nflTeams.length} NFL teams`);
            allTeams = [...allTeams, ...nflTeams];
          }
          
          // Wait between requests
          await new Promise(resolve => setTimeout(resolve, 2000));
        } catch (error) {
          console.log(`   ❌ ${approach.name} failed:`, error.message);
        }
      }
      
      // Remove duplicates based on team ID
      const uniqueTeams = allTeams.filter((team, index, self) => 
        index === self.findIndex(t => t.idTeam === team.idTeam)
      );
      
      console.log(`\n📊 Total unique NFL teams found: ${uniqueTeams.length}`);
      
      if (uniqueTeams.length > 0) {
        console.log('\n📋 NFL Teams:');
        uniqueTeams.forEach((team, index) => {
          console.log(`   ${index + 1}. ${team.strTeam} (${team.strAlternate || 'N/A'})`);
          console.log(`      ID: ${team.idTeam}`);
          console.log(`      League: ${team.strLeague}`);
          console.log(`      Stadium: ${team.strStadium}`);
          console.log(`      Founded: ${team.intFormedYear}`);
          console.log(`      Badge: ${team.strTeamBadge}`);
          console.log(`      Website: ${team.strWebsite}`);
          console.log('');
        });
      }
      
      return uniqueTeams;
    } catch (error) {
      console.error('❌ Failed to get NFL teams:', error.message);
      return [];
    }
  }

  // Get NFL games for 2025 season
  async getNFLGames2025() {
    console.log('\n🏈 Fetching NFL Games for 2025 Season...');
    
    try {
      const seasonApproaches = [
        '2025',
        '2025-2026',
        '2025-26',
        '2025 Season'
      ];
      
      let allEvents = [];
      
      for (const season of seasonApproaches) {
        try {
          console.log(`\n🔍 Searching for season: ${season}`);
          
          const result = await this.makeRequest('/searchevents.php', { 
            e: 'NFL',
            s: season
          });
          
          if (result.event) {
            console.log(`   Found ${result.event.length} events for ${season}`);
            allEvents = [...allEvents, ...result.event];
          }
          
          // Also try without specifying the event name
          const result2 = await this.makeRequest('/searchevents.php', { 
            s: season
          });
          
          if (result2.event) {
            const nflEvents = result2.event.filter(event => 
              event.strLeague && event.strLeague.toLowerCase().includes('nfl')
            );
            console.log(`   Found ${nflEvents.length} additional NFL events for ${season}`);
            allEvents = [...allEvents, ...nflEvents];
          }
          
          // Wait between requests
          await new Promise(resolve => setTimeout(resolve, 2000));
        } catch (error) {
          console.log(`   ❌ Season ${season} failed:`, error.message);
        }
      }
      
      // Remove duplicates
      const uniqueEvents = allEvents.filter((event, index, self) => 
        index === self.findIndex(e => e.idEvent === event.idEvent)
      );
      
      console.log(`\n📊 Total unique NFL events for 2025: ${uniqueEvents.length}`);
      
      if (uniqueEvents.length > 0) {
        console.log('\n📋 NFL 2025 Season Events:');
        uniqueEvents.slice(0, 20).forEach((event, index) => {
          console.log(`   ${index + 1}. ${event.strEvent}`);
          console.log(`      Date: ${event.dateEvent}`);
          console.log(`      Time: ${event.strTime}`);
          console.log(`      Home: ${event.strHomeTeam}`);
          console.log(`      Away: ${event.strAwayTeam}`);
          console.log(`      Venue: ${event.strVenue}`);
          console.log(`      Status: ${event.strStatus}`);
          console.log(`      Season: ${event.strSeason}`);
          console.log('');
        });
        
        if (uniqueEvents.length > 20) {
          console.log(`   ... and ${uniqueEvents.length - 20} more events`);
        }
      }
      
      return uniqueEvents;
    } catch (error) {
      console.error('❌ Failed to get NFL games for 2025:', error.message);
      return [];
    }
  }

  // Get upcoming NFL games
  async getUpcomingNFLGames() {
    console.log('\n🏈 Fetching Upcoming NFL Games...');
    
    try {
      // Get events for the next few days
      const today = new Date();
      const upcomingDates = [];
      
      for (let i = 0; i < 7; i++) {
        const date = new Date(today);
        date.setDate(date.getDate() + i);
        upcomingDates.push(date.toISOString().split('T')[0]);
      }
      
      let upcomingEvents = [];
      
      for (const date of upcomingDates) {
        try {
          console.log(`\n🔍 Searching for events on: ${date}`);
          
          const result = await this.makeRequest('/eventsday.php', { 
            d: date,
            s: 'American Football'
          });
          
          if (result.events) {
            const nflEvents = result.events.filter(event => 
              event.strLeague && event.strLeague.toLowerCase().includes('nfl')
            );
            console.log(`   Found ${nflEvents.length} NFL events on ${date}`);
            upcomingEvents = [...upcomingEvents, ...nflEvents];
          }
          
          // Wait between requests
          await new Promise(resolve => setTimeout(resolve, 2000));
        } catch (error) {
          console.log(`   ❌ Date ${date} failed:`, error.message);
        }
      }
      
      console.log(`\n📊 Total upcoming NFL events: ${upcomingEvents.length}`);
      
      if (upcomingEvents.length > 0) {
        console.log('\n📋 Upcoming NFL Games:');
        upcomingEvents.forEach((event, index) => {
          console.log(`   ${index + 1}. ${event.strEvent}`);
          console.log(`      Date: ${event.dateEvent}`);
          console.log(`      Time: ${event.strTime}`);
          console.log(`      Home: ${event.strHomeTeam}`);
          console.log(`      Away: ${event.strAwayTeam}`);
          console.log(`      Venue: ${event.strVenue}`);
          console.log('');
        });
      }
      
      return upcomingEvents;
    } catch (error) {
      console.error('❌ Failed to get upcoming NFL games:', error.message);
      return [];
    }
  }

  // Run comprehensive NFL data fetch
  async runNFLDataFetch() {
    console.log('🚀 Starting NFL Data Fetch from TheSportsDB');
    console.log('==========================================');
    console.log(`📡 Base URL: ${this.baseUrl}`);
    console.log(`⏱️  Rate Limit: ${this.maxRequestsPerMinute} requests per minute`);
    
    const results = {};
    
    try {
      // Find NFL league ID
      results.nflLeagueId = await this.findNFLLeagueId();
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Get all NFL teams
      results.teams = await this.getAllNFLTeams();
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Get NFL games for 2025
      results.games2025 = await this.getNFLGames2025();
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Get upcoming games
      results.upcomingGames = await this.getUpcomingNFLGames();
      
      console.log('\n✅ NFL Data Fetch Completed!');
      console.log('📊 Summary:');
      console.log(`   - NFL League ID: ${results.nflLeagueId || 'Not found'}`);
      console.log(`   - NFL Teams: ${results.teams.length}`);
      console.log(`   - 2025 Season Games: ${results.games2025.length}`);
      console.log(`   - Upcoming Games: ${results.upcomingGames.length}`);
      
      // Save results to file for inspection
      const fs = require('fs');
      const filename = `nfl-data-${new Date().toISOString().split('T')[0]}.json`;
      fs.writeFileSync(filename, JSON.stringify(results, null, 2));
      console.log(`\n💾 Results saved to: ${filename}`);
      
    } catch (error) {
      console.error('❌ NFL data fetch failed:', error.message);
    }
    
    return results;
  }
}

// Run the NFL data fetch if this file is executed directly
if (require.main === module) {
  const fetcher = new NFLDataFetcher();
  fetcher.runNFLDataFetch().catch(console.error);
}

module.exports = NFLDataFetcher;
