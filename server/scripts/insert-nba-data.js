const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const config = require('../config');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

// NBA Teams Data
const nbaTeams = [
  // Eastern Conference - Atlantic Division
  { name: 'Boston Celtics', city: 'Boston', abbreviation: 'BOS', conference: 'Eastern', division: 'Atlantic' },
  { name: 'Brooklyn Nets', city: 'Brooklyn', abbreviation: 'BKN', conference: 'Eastern', division: 'Atlantic' },
  { name: 'New York Knicks', city: 'New York', abbreviation: 'NYK', conference: 'Eastern', division: 'Atlantic' },
  { name: 'Philadelphia 76ers', city: 'Philadelphia', abbreviation: 'PHI', conference: 'Eastern', division: 'Atlantic' },
  { name: 'Toronto Raptors', city: 'Toronto', abbreviation: 'TOR', conference: 'Eastern', division: 'Atlantic' },
  
  // Eastern Conference - Central Division
  { name: 'Chicago Bulls', city: 'Chicago', abbreviation: 'CHI', conference: 'Eastern', division: 'Central' },
  { name: 'Cleveland Cavaliers', city: 'Cleveland', abbreviation: 'CLE', conference: 'Eastern', division: 'Central' },
  { name: 'Detroit Pistons', city: 'Detroit', abbreviation: 'DET', conference: 'Eastern', division: 'Central' },
  { name: 'Indiana Pacers', city: 'Indianapolis', abbreviation: 'IND', conference: 'Eastern', division: 'Central' },
  { name: 'Milwaukee Bucks', city: 'Milwaukee', abbreviation: 'MIL', conference: 'Eastern', division: 'Central' },
  
  // Eastern Conference - Southeast Division
  { name: 'Atlanta Hawks', city: 'Atlanta', abbreviation: 'ATL', conference: 'Eastern', division: 'Southeast' },
  { name: 'Charlotte Hornets', city: 'Charlotte', abbreviation: 'CHA', conference: 'Eastern', division: 'Southeast' },
  { name: 'Miami Heat', city: 'Miami', abbreviation: 'MIA', conference: 'Eastern', division: 'Southeast' },
  { name: 'Orlando Magic', city: 'Orlando', abbreviation: 'ORL', conference: 'Eastern', division: 'Southeast' },
  { name: 'Washington Wizards', city: 'Washington', abbreviation: 'WAS', conference: 'Eastern', division: 'Southeast' },
  
  // Western Conference - Northwest Division
  { name: 'Denver Nuggets', city: 'Denver', abbreviation: 'DEN', conference: 'Western', division: 'Northwest' },
  { name: 'Minnesota Timberwolves', city: 'Minneapolis', abbreviation: 'MIN', conference: 'Western', division: 'Northwest' },
  { name: 'Oklahoma City Thunder', city: 'Oklahoma City', abbreviation: 'OKC', conference: 'Western', division: 'Northwest' },
  { name: 'Portland Trail Blazers', city: 'Portland', abbreviation: 'POR', conference: 'Western', division: 'Northwest' },
  { name: 'Utah Jazz', city: 'Salt Lake City', abbreviation: 'UTA', conference: 'Western', division: 'Northwest' },
  
  // Western Conference - Pacific Division
  { name: 'Golden State Warriors', city: 'San Francisco', abbreviation: 'GSW', conference: 'Western', division: 'Pacific' },
  { name: 'Los Angeles Clippers', city: 'Los Angeles', abbreviation: 'LAC', conference: 'Western', division: 'Pacific' },
  { name: 'Los Angeles Lakers', city: 'Los Angeles', abbreviation: 'LAL', conference: 'Western', division: 'Pacific' },
  { name: 'Phoenix Suns', city: 'Phoenix', abbreviation: 'PHX', conference: 'Western', division: 'Pacific' },
  { name: 'Sacramento Kings', city: 'Sacramento', abbreviation: 'SAC', conference: 'Western', division: 'Pacific' },
  
  // Western Conference - Southwest Division
  { name: 'Dallas Mavericks', city: 'Dallas', abbreviation: 'DAL', conference: 'Western', division: 'Southwest' },
  { name: 'Houston Rockets', city: 'Houston', abbreviation: 'HOU', conference: 'Western', division: 'Southwest' },
  { name: 'Memphis Grizzlies', city: 'Memphis', abbreviation: 'MEM', conference: 'Western', division: 'Southwest' },
  { name: 'New Orleans Pelicans', city: 'New Orleans', abbreviation: 'NOP', conference: 'Western', division: 'Southwest' },
  { name: 'San Antonio Spurs', city: 'San Antonio', abbreviation: 'SAS', conference: 'Western', division: 'Southwest' }
];

const insertNBAData = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Start transaction
      db.run('BEGIN TRANSACTION');
      
      // Insert NBA League
      const leagueStmt = db.prepare(`
        INSERT OR REPLACE INTO leagues (id, name, abbreviation, sport, level, season, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `);
      
      leagueStmt.run('NBA', 'National Basketball Association', 'NBA', 'Basketball', 'Professional', '2024-25', 1);
      leagueStmt.finalize();
      
      console.log('✅ NBA League inserted');
      
      // Insert NBA Teams
      const teamStmt = db.prepare(`
        INSERT OR REPLACE INTO teams (id, name, city, abbreviation, league_id, conference, division)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `);
      
      let insertedCount = 0;
      nbaTeams.forEach(team => {
        const teamId = `NBA_${team.abbreviation}`;
        teamStmt.run(
          teamId,
          team.name,
          team.city,
          team.abbreviation,
          'NBA',
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
          console.log(`✅ Successfully inserted ${insertedCount} NBA teams`);
          resolve();
        }
      });
    });
  });
};

const verifyData = () => {
  return new Promise((resolve, reject) => {
    console.log('\n📊 Verifying NBA data...');
    
    // Check league
    db.get('SELECT * FROM leagues WHERE id = "NBA"', (err, row) => {
      if (err) {
        console.error('Error checking league:', err);
        reject(err);
      } else if (row) {
        console.log('✅ NBA League found:', row.name);
      } else {
        console.log('❌ NBA League not found');
      }
    });
    
    // Check teams count
    db.get('SELECT COUNT(*) as count FROM teams WHERE league_id = "NBA"', (err, row) => {
      if (err) {
        console.error('Error checking teams count:', err);
        reject(err);
      } else {
        console.log(`✅ Found ${row.count} NBA teams`);
        
        // Show teams by conference
        db.all('SELECT conference, COUNT(*) as count FROM teams WHERE league_id = "NBA" GROUP BY conference', (err, rows) => {
          if (err) {
            console.error('Error checking teams by conference:', err);
            reject(err);
          } else {
            console.log('\n📈 Teams by Conference:');
            rows.forEach(row => {
              console.log(`   ${row.conference}: ${row.count} teams`);
            });
            
            // Show teams by division
            db.all('SELECT conference, division, COUNT(*) as count FROM teams WHERE league_id = "NBA" GROUP BY conference, division ORDER BY conference, division', (err, rows) => {
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
    console.log('🏀 Starting NBA data insertion...');
    await insertNBAData();
    await verifyData();
    console.log('\n✅ NBA data insertion completed successfully!');
  } catch (error) {
    console.error('❌ Error inserting NBA data:', error);
  } finally {
    db.close();
  }
};

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { insertNBAData, verifyData };
