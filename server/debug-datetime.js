// Debug script to test datetime parsing
const database = require('./services/database');

async function debugDateTime() {
  try {
    console.log('Fetching games from database...');
    const games = await database.getGames('NBA');
    
    if (games.length === 0) {
      console.log('No games found in database');
      return;
    }
    
    console.log(`Found ${games.length} games`);
    console.log('\nFirst 3 games from database:');
    
    for (let i = 0; i < Math.min(3, games.length); i++) {
      const game = games[i];
      console.log(`\nGame ${i + 1}:`);
      console.log(`  ID: ${game.id}`);
      console.log(`  gameDate: ${game.gameDate} (type: ${typeof game.gameDate})`);
      console.log(`  gameTime: ${game.gameTime} (type: ${typeof game.gameTime})`);
      
      // Test the datetime creation logic
      const dateTimeString = `${game.gameDate}T${game.gameTime}Z`;
      const dateTime = new Date(dateTimeString);
      const isoString = dateTime.toISOString();
      
      console.log(`  Combined string: ${dateTimeString}`);
      console.log(`  Parsed date: ${dateTime}`);
      console.log(`  ISO string: ${isoString}`);
      console.log(`  Local time: ${dateTime.toLocaleString()}`);
    }
    
  } catch (error) {
    console.error('Error:', error);
  }
}

debugDateTime();
