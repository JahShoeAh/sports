const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');
const config = require('../config');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

// NBA Arena mapping with city and state
const nbaArenas = {
  'TD Garden': { city: 'Boston', state: 'MA' },
  'Crypto.com Arena': { city: 'Los Angeles', state: 'CA' },
  'Little Caesars Arena': { city: 'Detroit', state: 'MI' },
  'State Farm Arena': { city: 'Atlanta', state: 'GA' },
  'Kaseya Center': { city: 'Miami', state: 'FL' },
  'Wells Fargo Center': { city: 'Philadelphia', state: 'PA' },
  'Scotiabank Arena': { city: 'Toronto', state: 'ON' },
  'Toyota Center': { city: 'Houston', state: 'TX' },
  'Smoothie King Center': { city: 'New Orleans', state: 'LA' },
  'Fiserv Forum': { city: 'Milwaukee', state: 'WI' },
  'Target Center': { city: 'Minneapolis', state: 'MN' },
  'Chase Center': { city: 'San Francisco', state: 'CA' },
  'Footprint Center': { city: 'Phoenix', state: 'AZ' },
  'Moda Center': { city: 'Portland', state: 'OR' },
  'Vivint Arena': { city: 'Salt Lake City', state: 'UT' },
  'Golden 1 Center': { city: 'Sacramento', state: 'CA' },
  'American Airlines Center': { city: 'Dallas', state: 'TX' },
  'FedExForum': { city: 'Memphis', state: 'TN' },
  'AT&T Center': { city: 'San Antonio', state: 'TX' },
  'Spectrum Center': { city: 'Charlotte', state: 'NC' },
  'Amway Center': { city: 'Orlando', state: 'FL' },
  'Capital One Arena': { city: 'Washington', state: 'DC' },
  'United Center': { city: 'Chicago', state: 'IL' },
  'Rocket Mortgage FieldHouse': { city: 'Cleveland', state: 'OH' },
  'Gainbridge Fieldhouse': { city: 'Indianapolis', state: 'IN' },
  'Barclays Center': { city: 'Brooklyn', state: 'NY' },
  'Madison Square Garden': { city: 'New York', state: 'NY' },
  'Paycom Center': { city: 'Oklahoma City', state: 'OK' },
  'Ball Arena': { city: 'Denver', state: 'CO' },
  'Intuit Dome': { city: 'Los Angeles', state: 'CA' }
};

// Team name mapping to database abbreviations
const teamNameMapping = {
  'Boston Celtics': 'BOS',
  'New York Knicks': 'NYK',
  'Minnesota Timberwolves': 'MIN',
  'Los Angeles Lakers': 'LAL',
  'Indiana Pacers': 'IND',
  'Detroit Pistons': 'DET',
  'Brooklyn Nets': 'BKN',
  'Atlanta Hawks': 'ATL',
  'Orlando Magic': 'ORL',
  'Miami Heat': 'MIA',
  'Milwaukee Bucks': 'MIL',
  'Philadelphia 76ers': 'PHI',
  'Cleveland Cavaliers': 'CLE',
  'Toronto Raptors': 'TOR',
  'Charlotte Hornets': 'CHA',
  'Houston Rockets': 'HOU',
  'Chicago Bulls': 'CHI',
  'New Orleans Pelicans': 'NOP',
  'Golden State Warriors': 'GSW',
  'Phoenix Suns': 'PHX',
  'Portland Trail Blazers': 'POR',
  'Utah Jazz': 'UTA',
  'Sacramento Kings': 'SAC',
  'Dallas Mavericks': 'DAL',
  'Memphis Grizzlies': 'MEM',
  'San Antonio Spurs': 'SAS',
  'Washington Wizards': 'WAS',
  'Denver Nuggets': 'DEN',
  'Los Angeles Clippers': 'LAC',
  'Oklahoma City Thunder': 'OKC'
};

// Function to parse date from "Tue Oct 22 2024" format
function parseDate(dateStr) {
  const months = {
    'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
    'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
    'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
  };
  
  const parts = dateStr.split(' ');
  const month = months[parts[1]];
  const day = parts[2].padStart(2, '0');
  const year = parts[3];
  
  return `${year}-${month}-${day}`;
}

// Function to parse time from "7:30p" format
function parseTime(timeStr) {
  const isPM = timeStr.includes('p');
  let time = timeStr.replace(/[ap]/g, '');
  const [hours, minutes] = time.split(':');
  
  let hour24 = parseInt(hours);
  if (isPM && hour24 !== 12) {
    hour24 += 12;
  } else if (!isPM && hour24 === 12) {
    hour24 = 0;
  }
  
  return `${hour24.toString().padStart(2, '0')}:${minutes}:00`;
}

// Function to create venues table and insert venue data
const createVenuesTable = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Create venues table
      db.run(`
        CREATE TABLE IF NOT EXISTS venues (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          city TEXT NOT NULL,
          state TEXT NOT NULL,
          country TEXT DEFAULT 'USA',
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Insert NBA venues
      const venueStmt = db.prepare(`
        INSERT OR REPLACE INTO venues (id, name, city, state, country)
        VALUES (?, ?, ?, ?, ?)
      `);

      let venueCount = 0;
      Object.entries(nbaArenas).forEach(([arenaName, location]) => {
        const venueId = `VENUE_${arenaName.replace(/\s+/g, '_').toUpperCase()}`;
        venueStmt.run(venueId, arenaName, location.city, location.state, 'USA');
        venueCount++;
      });

      venueStmt.finalize();

      // Add overtime and nba_cup columns to games table
      db.run(`ALTER TABLE games ADD COLUMN overtime BOOLEAN DEFAULT 0`);
      db.run(`ALTER TABLE games ADD COLUMN nba_cup BOOLEAN DEFAULT 0`);

      console.log(`✅ Created venues table and inserted ${venueCount} NBA venues`);
      resolve();
    });
  });
};

// Function to process CSV and insert games
const processCSV = () => {
  return new Promise((resolve, reject) => {
    const csvPath = path.join(__dirname, '..', 'nba regular 2024 2025.csv');
    
    if (!fs.existsSync(csvPath)) {
      reject(new Error('CSV file not found'));
      return;
    }

    const csvContent = fs.readFileSync(csvPath, 'utf8');
    const lines = csvContent.split('\n');
    const headers = lines[0].split(',');
    
    console.log('📊 Processing NBA 2024-25 Regular Season games...');
    
    db.serialize(() => {
      db.run('BEGIN TRANSACTION');
      
      const gameStmt = db.prepare(`
        INSERT INTO games (
          id, home_team_id, away_team_id, league_id, season, 
          game_date, game_time, venue_id, venue, city, state, country,
          status, home_score, away_score, overtime, nba_cup, is_completed
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);

      let processedCount = 0;
      let skippedCount = 0;

      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;

        const values = line.split(',');
        if (values.length < 9) continue;

        try {
          const date = parseDate(values[0]);
          const time = parseTime(values[1]);
          const visitorTeam = values[2].trim();
          const visitorPoints = parseInt(values[3]);
          const homeTeam = values[4].trim();
          const homePoints = parseInt(values[5]);
          const overtime = values[6].trim() !== '';
          const arena = values[7].trim();
          const nbaCup = values[8].trim() !== '';

          // Get team IDs
          const visitorAbbr = teamNameMapping[visitorTeam];
          const homeAbbr = teamNameMapping[homeTeam];

          if (!visitorAbbr || !homeAbbr) {
            console.log(`⚠️  Skipping game: Unknown team names - ${visitorTeam} vs ${homeTeam}`);
            skippedCount++;
            continue;
          }

          const visitorTeamId = `NBA_${visitorAbbr}`;
          const homeTeamId = `NBA_${homeAbbr}`;
          const venueId = `VENUE_${arena.replace(/\s+/g, '_').toUpperCase()}`;
          const gameId = `NBA_${date.replace(/-/g, '')}_${homeAbbr}_${visitorAbbr}`;

          // Get venue info
          const venueInfo = nbaArenas[arena] || { city: 'Unknown', state: 'Unknown' };

          gameStmt.run(
            gameId,
            homeTeamId,
            visitorTeamId,
            'NBA',
            '2024-25 Regular',
            date,
            time,
            venueId,
            arena,
            venueInfo.city,
            venueInfo.state,
            'USA',
            'finished',
            homePoints,
            visitorPoints,
            overtime ? 1 : 0,
            nbaCup ? 1 : 0,
            1 // is_completed
          );

          processedCount++;
        } catch (error) {
          console.log(`⚠️  Error processing line ${i + 1}: ${error.message}`);
          skippedCount++;
        }
      }

      gameStmt.finalize();

      db.run('COMMIT', (err) => {
        if (err) {
          console.error('❌ Error committing transaction:', err);
          reject(err);
        } else {
          console.log(`✅ Successfully processed ${processedCount} games`);
          if (skippedCount > 0) {
            console.log(`⚠️  Skipped ${skippedCount} games due to errors`);
          }
          resolve();
        }
      });
    });
  });
};

// Function to verify the data
const verifyData = () => {
  return new Promise((resolve, reject) => {
    console.log('\n📊 Verifying NBA games data...');
    
    // Check total games
    db.get('SELECT COUNT(*) as count FROM games WHERE league_id = "NBA"', (err, row) => {
      if (err) {
        console.error('Error checking games count:', err);
        reject(err);
      } else {
        console.log(`✅ Found ${row.count} NBA games`);
        
        // Check games by season
        db.all('SELECT season, COUNT(*) as count FROM games WHERE league_id = "NBA" GROUP BY season', (err, rows) => {
          if (err) {
            console.error('Error checking games by season:', err);
            reject(err);
          } else {
            console.log('\n📈 Games by Season:');
            rows.forEach(row => {
              console.log(`   ${row.season}: ${row.count} games`);
            });
            
            // Check venues
            db.get('SELECT COUNT(*) as count FROM venues', (err, row) => {
              if (err) {
                console.error('Error checking venues count:', err);
                reject(err);
              } else {
                console.log(`✅ Found ${row.count} venues`);
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
    console.log('🏀 Starting NBA 2024-25 Regular Season data processing...');
    
    // Step 1: Create venues table and insert venue data
    await createVenuesTable();
    
    // Step 2: Process CSV and insert games
    await processCSV();
    
    // Step 3: Verify data
    await verifyData();
    
    console.log('\n✅ NBA games data processing completed successfully!');
  } catch (error) {
    console.error('❌ Error processing NBA games data:', error);
  } finally {
    db.close();
  }
};

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { createVenuesTable, processCSV, verifyData };
