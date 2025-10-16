const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '../data/sports.db');
const db = new sqlite3.Database(dbPath);

console.log('Fixing duplicate game IDs by adding number suffixes...\n');

// Function to create a new game ID with suffix
function createNewGameIdWithSuffix(originalId, suffix) {
  // Extract the base parts: NBA_YYYYMMDD_TEAM1_TEAM2
  const match = originalId.match(/^(NBA_\d{8}_[A-Z]{3}_[A-Z]{3})$/);
  if (!match) {
    console.log(`  ❌ Invalid game ID format: ${originalId}`);
    return null;
  }
  
  const baseId = match[1];
  return `${baseId}_${suffix}`;
}

// Get all games grouped by base ID
db.all(`
  SELECT 
    substr(id, 1, 15) as base_id,
    id as original_id,
    ROW_NUMBER() OVER (PARTITION BY substr(id, 1, 15) ORDER BY id) as row_num
  FROM games 
  WHERE leagueId = 'NBA'
  ORDER BY base_id, id
`, [], (err, games) => {
  if (err) {
    console.error('Error fetching games:', err);
    return;
  }
  
  // Group games by base ID
  const groupedGames = {};
  games.forEach(game => {
    if (!groupedGames[game.base_id]) {
      groupedGames[game.base_id] = [];
    }
    groupedGames[game.base_id].push(game);
  });
  
  // Find groups with duplicates
  const duplicateGroups = Object.entries(groupedGames).filter(([baseId, games]) => games.length > 1);
  
  console.log(`Found ${duplicateGroups.length} groups with duplicate base IDs:\n`);
  
  let totalUpdated = 0;
  let totalErrors = 0;
  let processedGroups = 0;
  
  duplicateGroups.forEach(([baseId, games]) => {
    console.log(`Group: ${baseId} (${games.length} games)`);
    
    // Keep the first game with original ID, add suffixes to the rest
    games.forEach((game, index) => {
      if (index === 0) {
        console.log(`  ✅ Keeping: ${game.original_id} (original)`);
        return;
      }
      
      const newId = createNewGameIdWithSuffix(game.original_id, index);
      if (!newId) {
        totalErrors++;
        return;
      }
      
      console.log(`  🔄 Updating: ${game.original_id} -> ${newId}`);
      
      // Update the game ID
      db.run(`
        UPDATE games 
        SET id = ? 
        WHERE id = ?
      `, [newId, game.original_id], function(err) {
        if (err) {
          console.log(`    ❌ Error updating ${game.original_id}: ${err.message}`);
          totalErrors++;
        } else {
          console.log(`    ✅ Updated successfully`);
          totalUpdated++;
        }
        
        processedGroups++;
        
        // Check if this is the last group
        if (processedGroups === duplicateGroups.length) {
          console.log(`\n📊 Summary:`);
          console.log(`  ✅ Updated: ${totalUpdated} games`);
          console.log(`  ❌ Errors: ${totalErrors} games`);
          
          // Verify no duplicates remain
          db.all(`
            SELECT substr(id, 1, 15) as base_id, COUNT(*) as count 
            FROM games 
            WHERE leagueId = 'NBA' 
            GROUP BY base_id 
            HAVING COUNT(*) > 1
          `, [], (err, remainingDuplicates) => {
            if (err) {
              console.error('Error checking for remaining duplicates:', err);
            } else {
              console.log(`\n🔍 Verification:`);
              if (remainingDuplicates.length === 0) {
                console.log(`  ✅ No duplicate base IDs remaining`);
              } else {
                console.log(`  ❌ ${remainingDuplicates.length} duplicate base IDs still exist:`);
                remainingDuplicates.forEach(dup => {
                  console.log(`    ${dup.base_id}: ${dup.count} games`);
                });
              }
            }
            
            db.close();
          });
        }
      });
    });
    
    console.log(''); // Empty line for readability
  });
});
