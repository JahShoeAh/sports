const sqlite3 = require('sqlite3').verbose();
const config = require('../config');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

// Helper function to convert number to simple numeric string
const numberToString = (num) => {
  return num.toString();
};

// Position distribution for realistic rosters (per team)
const positionDistribution = [
  { position: 'G', count: 4 },      // Guards
  { position: 'F', count: 4 },      // Forwards  
  { position: 'C', count: 2 },      // Centers
  { position: 'G-F', count: 1 },    // Guard-Forward
  { position: 'F-C', count: 1 }     // Forward-Center
];

// Height ranges by position (in inches)
const heightRanges = {
  'G': { min: 70, max: 78 },
  'F': { min: 76, max: 82 },
  'C': { min: 80, max: 87 },
  'G-F': { min: 74, max: 80 },
  'F-C': { min: 78, max: 84 }
};

// Weight ranges by position (in lbs)
const weightRanges = {
  'G': { min: 170, max: 220 },
  'F': { min: 200, max: 250 },
  'C': { min: 240, max: 280 },
  'G-F': { min: 180, max: 230 },
  'F-C': { min: 220, max: 260 }
};

// Nationalities for variety
const nationalities = [
  'USA', 'Canada', 'Australia', 'France', 'Germany', 'Spain', 'Italy', 'Serbia',
  'Croatia', 'Slovenia', 'Greece', 'Turkey', 'Brazil', 'Argentina', 'Mexico',
  'Nigeria', 'Senegal', 'Congo', 'Cameroon', 'South Sudan', 'Lithuania',
  'Latvia', 'Estonia', 'Poland', 'Czech Republic', 'Slovakia', 'Russia',
  'Ukraine', 'Georgia', 'Israel', 'Japan', 'China', 'Philippines', 'New Zealand'
];

// Injury status options
const injuryStatuses = ['Healthy', 'Day-to-day', 'Out', 'Injured Reserve', 'Questionable', 'Probable'];

// Generate random date between 19-38 years ago
const generateBirthdate = () => {
  const now = new Date();
  const minAge = 19;
  const maxAge = 38;
  const minDate = new Date(now.getFullYear() - maxAge, now.getMonth(), now.getDate());
  const maxDate = new Date(now.getFullYear() - minAge, now.getMonth(), now.getDate());
  const randomTime = minDate.getTime() + Math.random() * (maxDate.getTime() - minDate.getTime());
  return new Date(randomTime).toISOString().split('T')[0]; // YYYY-MM-DD format
};

// Generate random height within position range
const generateHeight = (position) => {
  const range = heightRanges[position];
  return Math.floor(Math.random() * (range.max - range.min + 1)) + range.min;
};

// Generate random weight within position range
const generateWeight = (position) => {
  const range = weightRanges[position];
  return Math.floor(Math.random() * (range.max - range.min + 1)) + range.min;
};

// Generate random draft year (2015-2024)
const generateDraftYear = () => {
  return Math.floor(Math.random() * 10) + 2015;
};

// Generate random draft pick (1-60)
const generateDraftPick = () => {
  return Math.floor(Math.random() * 60) + 1;
};

const seedPlayers = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Start transaction
      db.run('BEGIN TRANSACTION');
      
      // Get all NBA teams
      db.all('SELECT id, name FROM teams WHERE league_id = "NBA" ORDER BY id', (err, teams) => {
        if (err) {
          console.error('Error fetching teams:', err);
          reject(err);
          return;
        }
        
        if (teams.length !== 30) {
          console.error(`Expected 30 NBA teams, found ${teams.length}`);
          reject(new Error('Incorrect number of NBA teams'));
          return;
        }
        
        console.log(`Found ${teams.length} NBA teams`);
        
        // Prepare insert statement
        const stmt = db.prepare(`
          INSERT INTO players (
            id, team_id, display_name, first_name, last_name, jersey_number,
            primary_position, secondary_position, birthdate, height_inches, weight_lbs,
            nationality, photo_url, injury_status, draft_year, draft_pick_overall, active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `);
        
        let playerCount = 0;
        let teamIndex = 0;
        
        // Generate 12 players per team (360 total)
        for (let teamIndex = 0; teamIndex < teams.length; teamIndex++) {
          const team = teams[teamIndex];
          const positionPool = [];
          
          // Create position pool for this team
          positionDistribution.forEach(({ position, count }) => {
            for (let i = 0; i < count; i++) {
              positionPool.push(position);
            }
          });
          
          // Shuffle position pool
          for (let i = positionPool.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [positionPool[i], positionPool[j]] = [positionPool[j], positionPool[i]];
          }
          
          // Generate 12 players for this team
          for (let playerIndex = 0; playerIndex < 12; playerIndex++) {
            playerCount++;
            const playerNumber = playerCount;
            const position = positionPool[playerIndex];
            const displayName = `Player ${numberToString(playerNumber)}`;
            const firstName = 'Player';
            const lastName = numberToString(playerNumber);
            const jerseyNumber = playerIndex + 1; // 1-12
            const height = generateHeight(position);
            const weight = generateWeight(position);
            const birthdate = generateBirthdate();
            const nationality = nationalities[Math.floor(Math.random() * nationalities.length)];
            const injuryStatus = injuryStatuses[Math.floor(Math.random() * injuryStatuses.length)];
            const draftYear = generateDraftYear();
            const draftPick = generateDraftPick();
            const photoUrl = `https://via.placeholder.com/300x400/cccccc/666666?text=${firstName}+${lastName}`;
            
            // Generate secondary position (30% chance)
            let secondaryPosition = null;
            if (Math.random() < 0.3) {
              const secondaryOptions = positionDistribution
                .filter(p => p.position !== position)
                .map(p => p.position);
              secondaryPosition = secondaryOptions[Math.floor(Math.random() * secondaryOptions.length)];
            }
            
            const playerId = `${firstName}_${lastName}_${playerNumber}`;
            
            stmt.run([
              playerId,
              team.id,
              displayName,
              firstName,
              lastName,
              jerseyNumber,
              position,
              secondaryPosition,
              birthdate,
              height,
              weight,
              nationality,
              photoUrl,
              injuryStatus,
              draftYear,
              draftPick,
              1 // active
            ], function(err) {
              if (err) {
                console.error(`Error inserting player ${playerNumber}:`, err);
              }
            });
          }
        }
        
        stmt.finalize();
        
        // Commit transaction
        db.run('COMMIT', (err) => {
          if (err) {
            console.error('❌ Error committing transaction:', err);
            reject(err);
          } else {
            console.log(`✅ Successfully inserted ${playerCount} players`);
            resolve();
          }
        });
      });
    });
  });
};

const verifyPlayers = () => {
  return new Promise((resolve, reject) => {
    console.log('\n📊 Verifying player data...');
    
    // Check total players
    db.get('SELECT COUNT(*) as count FROM players', (err, row) => {
      if (err) {
        console.error('Error checking players count:', err);
        reject(err);
      } else {
        console.log(`✅ Found ${row.count} total players`);
        
        // Check players per team
        db.all(`
          SELECT t.name, COUNT(p.id) as player_count 
          FROM teams t 
          LEFT JOIN players p ON t.id = p.team_id 
          WHERE t.league_id = "NBA" 
          GROUP BY t.id, t.name 
          ORDER BY t.name
        `, (err, rows) => {
          if (err) {
            console.error('Error checking players per team:', err);
            reject(err);
          } else {
            console.log('\n📈 Players per team:');
            rows.forEach(row => {
              console.log(`   ${row.name}: ${row.player_count} players`);
            });
            
            // Check position distribution
            db.all(`
              SELECT primary_position, COUNT(*) as count 
              FROM players 
              GROUP BY primary_position 
              ORDER BY count DESC
            `, (err, rows) => {
              if (err) {
                console.error('Error checking position distribution:', err);
                reject(err);
              } else {
                console.log('\n📈 Position distribution:');
                rows.forEach(row => {
                  console.log(`   ${row.primary_position}: ${row.count} players`);
                });
                
                // Check nationality distribution
                db.all(`
                  SELECT nationality, COUNT(*) as count 
                  FROM players 
                  GROUP BY nationality 
                  ORDER BY count DESC 
                  LIMIT 10
                `, (err, rows) => {
                  if (err) {
                    console.error('Error checking nationality distribution:', err);
                    reject(err);
                  } else {
                    console.log('\n📈 Top nationalities:');
                    rows.forEach(row => {
                      console.log(`   ${row.nationality}: ${row.count} players`);
                    });
                    resolve();
                  }
                });
              }
            });
          }
        });
      }
    });
  });
};

// Main execution
const main = async () => {
  try {
    console.log('🏀 Starting NBA player seeding...');
    await seedPlayers();
    await verifyPlayers();
    console.log('\n✅ NBA player seeding completed successfully!');
  } catch (error) {
    console.error('❌ Error seeding players:', error);
    process.exit(1);
  } finally {
    db.close();
  }
};

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { seedPlayers, verifyPlayers };
