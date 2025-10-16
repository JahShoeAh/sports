const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '../data/sports.db');
const db = new sqlite3.Database(dbPath);

console.log('Fixing remaining games with time-only format...\n');

// Function to convert time-only format to full ISO datetime
function convertTimeToISO(gameId, timeString) {
  // Extract date from game ID (format: NBA_YYYYMMDD_TEAM1_TEAM2)
  const dateMatch = gameId.match(/NBA_(\d{4})(\d{2})(\d{2})_/);
  if (!dateMatch) {
    console.log(`  ❌ Could not extract date from game ID: ${gameId}`);
    return null;
  }
  
  const [, year, month, day] = dateMatch;
  const dateString = `${year}-${month}-${day}`;
  
  // Combine date and time to create full ISO datetime
  const fullDateTime = `${dateString}T${timeString}Z`;
  
  // Validate the datetime
  const testDate = new Date(fullDateTime);
  if (isNaN(testDate.getTime())) {
    console.log(`  ❌ Invalid datetime: ${fullDateTime}`);
    return null;
  }
  
  return fullDateTime;
}

// Get games that need fixing
db.all(`
  SELECT id, gameTime 
  FROM games 
  WHERE leagueId = 'NBA' AND length(gameTime) <= 10
`, [], (err, games) => {
  if (err) {
    console.error('Error fetching games:', err);
    return;
  }
  
  console.log(`Found ${games.length} games to fix:\n`);
  
  let fixedCount = 0;
  let errorCount = 0;
  
  games.forEach((game, index) => {
    console.log(`${index + 1}. ${game.id} | ${game.gameTime}`);
    
    const newGameTime = convertTimeToISO(game.id, game.gameTime);
    if (!newGameTime) {
      errorCount++;
      return;
    }
    
    // Update the game
    db.run(`
      UPDATE games 
      SET gameTime = ? 
      WHERE id = ?
    `, [newGameTime, game.id], function(err) {
      if (err) {
        console.log(`  ❌ Error updating ${game.id}: ${err.message}`);
        errorCount++;
      } else {
        console.log(`  ✅ Updated to: ${newGameTime}`);
        fixedCount++;
      }
      
      // Check if this is the last game
      if (index === games.length - 1) {
        console.log(`\n📊 Summary:`);
        console.log(`  ✅ Fixed: ${fixedCount} games`);
        console.log(`  ❌ Errors: ${errorCount} games`);
        
        // Verify the fix
        db.all(`
          SELECT COUNT(*) as total_games, 
                 SUM(CASE WHEN length(gameTime) > 10 THEN 1 ELSE 0 END) as full_datetime, 
                 SUM(CASE WHEN length(gameTime) <= 10 THEN 1 ELSE 0 END) as time_only 
          FROM games 
          WHERE leagueId = 'NBA'
        `, [], (err, result) => {
          if (err) {
            console.error('Error verifying fix:', err);
          } else {
            console.log(`\n🔍 Verification:`);
            console.log(`  Total games: ${result[0].total_games}`);
            console.log(`  Full datetime: ${result[0].full_datetime}`);
            console.log(`  Time only: ${result[0].time_only}`);
          }
          
          db.close();
        });
      }
    });
  });
});
