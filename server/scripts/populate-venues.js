const sqlite3 = require('sqlite3').verbose();
const config = require('../config');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

const populateVenues = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      console.log('Populating venues...');

      // Sample venues for NBA teams
      const venues = [
        {
          id: 'CHASE_CENTER',
          name: 'Chase Center',
          city: 'San Francisco',
          state: 'CA',
          country: 'USA',
          homeTeamId: 'NBA_GSW'
        },
        {
          id: 'CRYPTO_COM_ARENA',
          name: 'Crypto.com Arena',
          city: 'Los Angeles',
          state: 'CA',
          country: 'USA',
          homeTeamId: 'NBA_LAC'
        },
        {
          id: 'CRYPTO_COM_ARENA_LAL',
          name: 'Crypto.com Arena',
          city: 'Los Angeles',
          state: 'CA',
          country: 'USA',
          homeTeamId: 'NBA_LAL'
        },
        {
          id: 'FOOTPRINT_CENTER',
          name: 'Footprint Center',
          city: 'Phoenix',
          state: 'AZ',
          country: 'USA',
          homeTeamId: 'NBA_PHX'
        },
        {
          id: 'BALL_ARENA',
          name: 'Ball Arena',
          city: 'Denver',
          state: 'CO',
          country: 'USA',
          homeTeamId: 'NBA_DEN'
        },
        {
          id: 'VIVINT_ARENA',
          name: 'Vivint Arena',
          city: 'Salt Lake City',
          state: 'UT',
          country: 'USA',
          homeTeamId: 'NBA_UTA'
        },
        {
          id: 'MODA_CENTER',
          name: 'Moda Center',
          city: 'Portland',
          state: 'OR',
          country: 'USA',
          homeTeamId: 'NBA_POR'
        },
        {
          id: 'GOLDEN_1_CENTER',
          name: 'Golden 1 Center',
          city: 'Sacramento',
          state: 'CA',
          country: 'USA',
          homeTeamId: 'NBA_SAC'
        },
        {
          id: 'TD_GARDEN',
          name: 'TD Garden',
          city: 'Boston',
          state: 'MA',
          country: 'USA',
          homeTeamId: 'NBA_BOS'
        },
        {
          id: 'FTX_ARENA',
          name: 'FTX Arena',
          city: 'Miami',
          state: 'FL',
          country: 'USA',
          homeTeamId: 'NBA_MIA'
        },
        {
          id: 'MADISON_SQUARE_GARDEN',
          name: 'Madison Square Garden',
          city: 'New York',
          state: 'NY',
          country: 'USA',
          homeTeamId: 'NBA_NYK'
        },
        {
          id: 'BARCLAYS_CENTER',
          name: 'Barclays Center',
          city: 'Brooklyn',
          state: 'NY',
          country: 'USA',
          homeTeamId: 'NBA_BKN'
        },
        {
          id: 'WELLS_FARGO_CENTER',
          name: 'Wells Fargo Center',
          city: 'Philadelphia',
          state: 'PA',
          country: 'USA',
          homeTeamId: 'NBA_PHI'
        },
        {
          id: 'SCOTIABANK_ARENA',
          name: 'Scotiabank Arena',
          city: 'Toronto',
          state: 'ON',
          country: 'Canada',
          homeTeamId: 'NBA_TOR'
        },
        {
          id: 'UNITED_CENTER',
          name: 'United Center',
          city: 'Chicago',
          state: 'IL',
          country: 'USA',
          homeTeamId: 'NBA_CHI'
        },
        {
          id: 'ROCKET_MORTGAGE_FIELDHOUSE',
          name: 'Rocket Mortgage FieldHouse',
          city: 'Cleveland',
          state: 'OH',
          country: 'USA',
          homeTeamId: 'NBA_CLE'
        },
        {
          id: 'LITTLE_CAESARS_ARENA',
          name: 'Little Caesars Arena',
          city: 'Detroit',
          state: 'MI',
          country: 'USA',
          homeTeamId: 'NBA_DET'
        },
        {
          id: 'GAINBRIDGE_FIELDHOUSE',
          name: 'Gainbridge Fieldhouse',
          city: 'Indianapolis',
          state: 'IN',
          country: 'USA',
          homeTeamId: 'NBA_IND'
        },
        {
          id: 'FISERV_FORUM',
          name: 'Fiserv Forum',
          city: 'Milwaukee',
          state: 'WI',
          country: 'USA',
          homeTeamId: 'NBA_MIL'
        },
        {
          id: 'STATE_FARM_ARENA',
          name: 'State Farm Arena',
          city: 'Atlanta',
          state: 'GA',
          country: 'USA',
          homeTeamId: 'NBA_ATL'
        },
        {
          id: 'SPECTRUM_CENTER',
          name: 'Spectrum Center',
          city: 'Charlotte',
          state: 'NC',
          country: 'USA',
          homeTeamId: 'NBA_CHA'
        },
        {
          id: 'AMWAY_CENTER',
          name: 'Amway Center',
          city: 'Orlando',
          state: 'FL',
          country: 'USA',
          homeTeamId: 'NBA_ORL'
        },
        {
          id: 'CAPITAL_ONE_ARENA',
          name: 'Capital One Arena',
          city: 'Washington',
          state: 'DC',
          country: 'USA',
          homeTeamId: 'NBA_WAS'
        },
        {
          id: 'AMERICAN_AIRLINES_CENTER',
          name: 'American Airlines Center',
          city: 'Dallas',
          state: 'TX',
          country: 'USA',
          homeTeamId: 'NBA_DAL'
        },
        {
          id: 'TOYOTA_CENTER',
          name: 'Toyota Center',
          city: 'Houston',
          state: 'TX',
          country: 'USA',
          homeTeamId: 'NBA_HOU'
        },
        {
          id: 'FEDEX_FORUM',
          name: 'FedExForum',
          city: 'Memphis',
          state: 'TN',
          country: 'USA',
          homeTeamId: 'NBA_MEM'
        },
        {
          id: 'SMOOTHIE_KING_CENTER',
          name: 'Smoothie King Center',
          city: 'New Orleans',
          state: 'LA',
          country: 'USA',
          homeTeamId: 'NBA_NOP'
        },
        {
          id: 'AT_T_CENTER',
          name: 'AT&T Center',
          city: 'San Antonio',
          state: 'TX',
          country: 'USA',
          homeTeamId: 'NBA_SAS'
        },
        {
          id: 'PAYCOM_CENTER',
          name: 'Paycom Center',
          city: 'Oklahoma City',
          state: 'OK',
          country: 'USA',
          homeTeamId: 'NBA_OKC'
        },
        {
          id: 'TARGET_CENTER',
          name: 'Target Center',
          city: 'Minneapolis',
          state: 'MN',
          country: 'USA',
          homeTeamId: 'NBA_MIN'
        }
      ];

      const stmt = db.prepare(`
        INSERT OR IGNORE INTO venues (id, name, city, state, country, home_team_id)
        VALUES (?, ?, ?, ?, ?, ?)
      `);

      venues.forEach(venue => {
        stmt.run([
          venue.id,
          venue.name,
          venue.city,
          venue.state,
          venue.country,
          venue.homeTeamId
        ], (err) => {
          if (err) {
            console.error(`Error inserting venue ${venue.name}:`, err);
          } else {
            console.log(`✓ Created venue: ${venue.name} (${venue.city}, ${venue.state})`);
          }
        });
      });

      stmt.finalize();

      console.log('Venue population completed!');
      resolve();
    });
  });
};

// Run population if called directly
if (require.main === module) {
  populateVenues()
    .then(() => {
      console.log('Venue population completed successfully');
      db.close();
      process.exit(0);
    })
    .catch((error) => {
      console.error('Venue population failed:', error);
      db.close();
      process.exit(1);
    });
}

module.exports = { populateVenues };
