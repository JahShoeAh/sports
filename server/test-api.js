// Quick test script to debug the API-Sports response
const axios = require('axios');

const apiKey = '9316aa1d2d0c2d55eb84b0dc566fc21a';
const baseURL = 'https://v1.american-football.api-sports.io';

async function testAPI() {
  console.log('🔍 Testing API-Sports.io responses...\n');
  
  try {
    // Test 1: Check API status
    console.log('1. Testing API status...');
    const statusResponse = await axios.get(`${baseURL}/status`, {
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'v1.american-football.api-sports.io'
      }
    });
    console.log('✅ API Status:', statusResponse.data);
    console.log('');
    
    // Test 2: Try teams with different seasons
    console.log('2. Testing teams endpoint...');
    const seasons = ['2024', '2025', '2023'];
    
    for (const season of seasons) {
      try {
        console.log(`   Trying season ${season}...`);
        const teamsResponse = await axios.get(`${baseURL}/teams`, {
          headers: {
            'X-RapidAPI-Key': apiKey,
            'X-RapidAPI-Host': 'v1.american-football.api-sports.io'
          },
          params: {
            league: '1',
            season: season
          }
        });
        
        console.log(`   Season ${season}: ${teamsResponse.data.response?.length || 0} teams`);
        if (teamsResponse.data.response?.length > 0) {
          console.log(`   ✅ Found data for season ${season}!`);
          console.log(`   Sample team:`, teamsResponse.data.response[0]);
        }
      } catch (error) {
        console.log(`   ❌ Season ${season} failed:`, error.message);
      }
    }
    console.log('');
    
    // Test 3: Try games endpoint with different parameters
    console.log('3. Testing games endpoint...');
    const gameSeasons = ['2024', '2023'];
    
    for (const season of gameSeasons) {
      try {
        console.log(`   Trying games for season ${season}...`);
        const gamesResponse = await axios.get(`${baseURL}/games`, {
          headers: {
            'X-RapidAPI-Key': apiKey,
            'X-RapidAPI-Host': 'v1.american-football.api-sports.io'
          },
          params: {
            league: '1',
            season: season
          }
        });
        
        console.log(`   Season ${season}: ${gamesResponse.data.response?.length || 0} games`);
        if (gamesResponse.data.response?.length > 0) {
          console.log(`   ✅ Found games for season ${season}!`);
          console.log(`   Sample game:`, gamesResponse.data.response[0]);
          break; // Found data, stop testing
        }
      } catch (error) {
        console.log(`   ❌ Season ${season} games failed:`, error.message);
      }
    }
    
    // Test 4: Try games without season parameter
    console.log('4. Testing games without season parameter...');
    try {
      const gamesResponse = await axios.get(`${baseURL}/games`, {
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': 'v1.american-football.api-sports.io'
        },
        params: {
          league: '1'
        }
      });
      
      console.log(`   Games (no season): ${gamesResponse.data.response?.length || 0} games`);
      if (gamesResponse.data.response?.length > 0) {
        console.log(`   ✅ Found games without season parameter!`);
        console.log(`   Sample game:`, gamesResponse.data.response[0]);
      }
    } catch (error) {
      console.log(`   ❌ Games without season failed:`, error.message);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testAPI();
