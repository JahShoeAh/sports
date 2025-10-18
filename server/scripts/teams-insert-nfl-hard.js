const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const config = require('../config');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

// NFL Teams Data
const nflTeams = [
  // American Football Conference (AFC) - East Division
  { name: 'Buffalo Bills', city: 'Buffalo', abbreviation: 'BUF', conference: 'AFC', division: 'East' },
  { name: 'Miami Dolphins', city: 'Miami', abbreviation: 'MIA', conference: 'AFC', division: 'East' },
  { name: 'New England Patriots', city: 'New England', abbreviation: 'NE', conference: 'AFC', division: 'East' },
  { name: 'New York Jets', city: 'New York', abbreviation: 'NYJ', conference: 'AFC', division: 'East' },
  
  // American Football Conference (AFC) - North Division
  { name: 'Baltimore Ravens', city: 'Baltimore', abbreviation: 'BAL', conference: 'AFC', division: 'North' },
  { name: 'Cincinnati Bengals', city: 'Cincinnati', abbreviation: 'CIN', conference: 'AFC', division: 'North' },
  { name: 'Cleveland Browns', city: 'Cleveland', abbreviation: 'CLE', conference: 'AFC', division: 'North' },
  { name: 'Pittsburgh Steelers', city: 'Pittsburgh', abbreviation: 'PIT', conference: 'AFC', division: 'North' },
  
  // American Football Conference (AFC) - South Division
  { name: 'Houston Texans', city: 'Houston', abbreviation: 'HOU', conference: 'AFC', division: 'South' },
  { name: 'Indianapolis Colts', city: 'Indianapolis', abbreviation: 'IND', conference: 'AFC', division: 'South' },
  { name: 'Jacksonville Jaguars', city: 'Jacksonville', abbreviation: 'JAX', conference: 'AFC', division: 'South' },
  { name: 'Tennessee Titans', city: 'Nashville', abbreviation: 'TEN', conference: 'AFC', division: 'South' },
  
  // American Football Conference (AFC) - West Division
  { name: 'Denver Broncos', city: 'Denver', abbreviation: 'DEN', conference: 'AFC', division: 'West' },
  { name: 'Kansas City Chiefs', city: 'Kansas City', abbreviation: 'KC', conference: 'AFC', division: 'West' },
  { name: 'Las Vegas Raiders', city: 'Las Vegas', abbreviation: 'LV', conference: 'AFC', division: 'West' },
  { name: 'Los Angeles Chargers', city: 'Los Angeles', abbreviation: 'LAC', conference: 'AFC', division: 'West' },
  
  // National Football Conference (NFC) - East Division
  { name: 'Dallas Cowboys', city: 'Dallas', abbreviation: 'DAL', conference: 'NFC', division: 'East' },
  { name: 'New York Giants', city: 'New York', abbreviation: 'NYG', conference: 'NFC', division: 'East' },
  { name: 'Philadelphia Eagles', city: 'Philadelphia', abbreviation: 'PHI', conference: 'NFC', division: 'East' },
  { name: 'Washington Commanders', city: 'Washington', abbreviation: 'WAS', conference: 'NFC', division: 'East' },
  
  // National Football Conference (NFC) - North Division
  { name: 'Chicago Bears', city: 'Chicago', abbreviation: 'CHI', conference: 'NFC', division: 'North' },
  { name: 'Detroit Lions', city: 'Detroit', abbreviation: 'DET', conference: 'NFC', division: 'North' },
  { name: 'Green Bay Packers', city: 'Green Bay', abbreviation: 'GB', conference: 'NFC', division: 'North' },
  { name: 'Minnesota Vikings', city: 'Minneapolis', abbreviation: 'MIN', conference: 'NFC', division: 'North' },
  
  // National Football Conference (NFC) - South Division
  { name: 'Atlanta Falcons', city: 'Atlanta', abbreviation: 'ATL', conference: 'NFC', division: 'South' },
  { name: 'Carolina Panthers', city: 'Charlotte', abbreviation: 'CAR', conference: 'NFC', division: 'South' },
  { name: 'New Orleans Saints', city: 'New Orleans', abbreviation: 'NO', conference: 'NFC', division: 'South' },
  { name: 'Tampa Bay Buccaneers', city: 'Tampa Bay', abbreviation: 'TB', conference: 'NFC', division: 'South' },
  
  // National Football Conference (NFC) - West Division
  { name: 'Arizona Cardinals', city: 'Phoenix', abbreviation: 'ARI', conference: 'NFC', division: 'West' },
  { name: 'Los Angeles Rams', city: 'Los Angeles', abbreviation: 'LAR', conference: 'NFC', division: 'West' },
  { name: 'San Francisco 49ers', city: 'San Francisco', abbreviation: 'SF', conference: 'NFC', division: 'West' },
  { name: 'Seattle Seahawks', city: 'Seattle', abbreviation: 'SEA', conference: 'NFC', division: 'West' }
];

const insertNFLData = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Start transaction
      db.run('BEGIN TRANSACTION');
      
      // Insert NFL League
      const leagueStmt = db.prepare(`
        INSERT OR REPLACE INTO leagues (id, name, abbreviation, sport, level, is_active)
        VALUES (?, ?, ?, ?, ?, ?)
      `);
      
      leagueStmt.run('NFL', 'National Football League', 'NFL', 'football', 'professional', 1);
      leagueStmt.finalize();
      
      console.log('✅ NFL League inserted');
      
      // Insert NFL Teams
      const teamStmt = db.prepare(`
        INSERT OR REPLACE INTO teams (id, name, city, abbreviation, league_id, conference, division)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `);
      
      let insertedCount = 0;
      nflTeams.forEach(team => {
        const teamId = `NFL_${team.abbreviation}`;
        teamStmt.run(
          teamId,
          team.name,
          team.city,
          team.abbreviation,
          'NFL',
          team.conference,
          team.division
        );
        insertedCount++;
      });
      
      teamStmt.finalize();
      
      // Commit transaction
      db.run('COMMIT', (err) => {
        if (err) {
          console.error('❌ Error committing transaction:', err);
          reject(err);
        } else {
          console.log(`✅ Successfully inserted ${insertedCount} NFL teams`);
          resolve();
        }
      });
    });
  });
};

const verifyData = () => {
  return new Promise((resolve, reject) => {
    console.log('\n📊 Verifying NFL data...');
    
    // Check league
    db.get('SELECT * FROM leagues WHERE id = "NFL"', (err, row) => {
      if (err) {
        console.error('Error checking league:', err);
        reject(err);
      } else if (row) {
        console.log('✅ NFL League found:', row.name);
      } else {
        console.log('❌ NFL League not found');
      }
    });
    
    // Check teams count
    db.get('SELECT COUNT(*) as count FROM teams WHERE league_id = "NFL"', (err, row) => {
      if (err) {
        console.error('Error checking teams count:', err);
        reject(err);
      } else {
        console.log(`✅ Found ${row.count} NFL teams`);
        
        // Show teams by conference
        db.all('SELECT conference, COUNT(*) as count FROM teams WHERE league_id = "NFL" GROUP BY conference', (err, rows) => {
          if (err) {
            console.error('Error checking teams by conference:', err);
            reject(err);
          } else {
            console.log('\n📈 Teams by Conference:');
            rows.forEach(row => {
              console.log(`   ${row.conference}: ${row.count} teams`);
            });
            
            // Show teams by division
            db.all('SELECT conference, division, COUNT(*) as count FROM teams WHERE league_id = "NFL" GROUP BY conference, division ORDER BY conference, division', (err, rows) => {
              if (err) {
                console.error('Error checking teams by division:', err);
                reject(err);
              } else {
                console.log('\n📈 Teams by Division:');
                rows.forEach(row => {
                  console.log(`   ${row.conference} - ${row.division}: ${row.count} teams`);
                });
                resolve();
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
    console.log('🏈 Starting NFL data insertion...');
    await insertNFLData();
    await verifyData();
    console.log('\n✅ NFL data insertion completed successfully!');
  } catch (error) {
    console.error('❌ Error inserting NFL data:', error);
  } finally {
    db.close();
  }
};

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { insertNFLData, verifyData };
