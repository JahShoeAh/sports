const sqlite3 = require('sqlite3').verbose();
const config = require('../config');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

const populateGamesWithVenues = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      console.log('Populating games with venue objects...');

      // Sample venue objects for NBA teams
      const venueMap = {
        'NBA_GSW': {
          id: 'CHASE_CENTER',
          name: 'Chase Center',
          city: 'San Francisco',
          state: 'CA',
          country: 'USA',
          homeTeamId: 'NBA_GSW'
        },
        'NBA_LAC': {
          id: 'CRYPTO_COM_ARENA',
          name: 'Crypto.com Arena',
          city: 'Los Angeles',
          state: 'CA',
          country: 'USA',
          homeTeamId: 'NBA_LAC'
        },
        'NBA_LAL': {
          id: 'CRYPTO_COM_ARENA_LAL',
          name: 'Crypto.com Arena',
          city: 'Los Angeles',
          state: 'CA',
          country: 'USA',
          homeTeamId: 'NBA_LAL'
        },
        'NBA_PHX': {
          id: 'FOOTPRINT_CENTER',
          name: 'Footprint Center',
          city: 'Phoenix',
          state: 'AZ',
          country: 'USA',
          homeTeamId: 'NBA_PHX'
        },
        'NBA_DEN': {
          id: 'BALL_ARENA',
          name: 'Ball Arena',
          city: 'Denver',
          state: 'CO',
          country: 'USA',
          homeTeamId: 'NBA_DEN'
        },
        'NBA_UTA': {
          id: 'VIVINT_ARENA',
          name: 'Vivint Arena',
          city: 'Salt Lake City',
          state: 'UT',
          country: 'USA',
          homeTeamId: 'NBA_UTA'
        },
        'NBA_POR': {
          id: 'MODA_CENTER',
          name: 'Moda Center',
          city: 'Portland',
          state: 'OR',
          country: 'USA',
          homeTeamId: 'NBA_POR'
        },
        'NBA_SAC': {
          id: 'GOLDEN_1_CENTER',
          name: 'Golden 1 Center',
          city: 'Sacramento',
          state: 'CA',
          country: 'USA',
          homeTeamId: 'NBA_SAC'
        },
        'NBA_BOS': {
          id: 'TD_GARDEN',
          name: 'TD Garden',
          city: 'Boston',
          state: 'MA',
          country: 'USA',
          homeTeamId: 'NBA_BOS'
        },
        'NBA_MIA': {
          id: 'FTX_ARENA',
          name: 'FTX Arena',
          city: 'Miami',
          state: 'FL',
          country: 'USA',
          homeTeamId: 'NBA_MIA'
        },
        'NBA_NYK': {
          id: 'MADISON_SQUARE_GARDEN',
          name: 'Madison Square Garden',
          city: 'New York',
          state: 'NY',
          country: 'USA',
          homeTeamId: 'NBA_NYK'
        },
        'NBA_BKN': {
          id: 'BARCLAYS_CENTER',
          name: 'Barclays Center',
          city: 'Brooklyn',
          state: 'NY',
          country: 'USA',
          homeTeamId: 'NBA_BKN'
        },
        'NBA_PHI': {
          id: 'WELLS_FARGO_CENTER',
          name: 'Wells Fargo Center',
          city: 'Philadelphia',
          state: 'PA',
          country: 'USA',
          homeTeamId: 'NBA_PHI'
        },
        'NBA_TOR': {
          id: 'SCOTIABANK_ARENA',
          name: 'Scotiabank Arena',
          city: 'Toronto',
          state: 'ON',
          country: 'Canada',
          homeTeamId: 'NBA_TOR'
        },
        'NBA_CHI': {
          id: 'UNITED_CENTER',
          name: 'United Center',
          city: 'Chicago',
          state: 'IL',
          country: 'USA',
          homeTeamId: 'NBA_CHI'
        },
        'NBA_CLE': {
          id: 'ROCKET_MORTGAGE_FIELDHOUSE',
          name: 'Rocket Mortgage FieldHouse',
          city: 'Cleveland',
          state: 'OH',
          country: 'USA',
          homeTeamId: 'NBA_CLE'
        },
        'NBA_DET': {
          id: 'LITTLE_CAESARS_ARENA',
          name: 'Little Caesars Arena',
          city: 'Detroit',
          state: 'MI',
          country: 'USA',
          homeTeamId: 'NBA_DET'
        },
        'NBA_IND': {
          id: 'GAINBRIDGE_FIELDHOUSE',
          name: 'Gainbridge Fieldhouse',
          city: 'Indianapolis',
          state: 'IN',
          country: 'USA',
          homeTeamId: 'NBA_IND'
        },
        'NBA_MIL': {
          id: 'FISERV_FORUM',
          name: 'Fiserv Forum',
          city: 'Milwaukee',
          state: 'WI',
          country: 'USA',
          homeTeamId: 'NBA_MIL'
        },
        'NBA_ATL': {
          id: 'STATE_FARM_ARENA',
          name: 'State Farm Arena',
          city: 'Atlanta',
          state: 'GA',
          country: 'USA',
          homeTeamId: 'NBA_ATL'
        },
        'NBA_CHA': {
          id: 'SPECTRUM_CENTER',
          name: 'Spectrum Center',
          city: 'Charlotte',
          state: 'NC',
          country: 'USA',
          homeTeamId: 'NBA_CHA'
        },
        'NBA_ORL': {
          id: 'AMWAY_CENTER',
          name: 'Amway Center',
          city: 'Orlando',
          state: 'FL',
          country: 'USA',
          homeTeamId: 'NBA_ORL'
        },
        'NBA_WAS': {
          id: 'CAPITAL_ONE_ARENA',
          name: 'Capital One Arena',
          city: 'Washington',
          state: 'DC',
          country: 'USA',
          homeTeamId: 'NBA_WAS'
        },
        'NBA_DAL': {
          id: 'AMERICAN_AIRLINES_CENTER',
          name: 'American Airlines Center',
          city: 'Dallas',
          state: 'TX',
          country: 'USA',
          homeTeamId: 'NBA_DAL'
        },
        'NBA_HOU': {
          id: 'TOYOTA_CENTER',
          name: 'Toyota Center',
          city: 'Houston',
          state: 'TX',
          country: 'USA',
          homeTeamId: 'NBA_HOU'
        },
        'NBA_MEM': {
          id: 'FEDEX_FORUM',
          name: 'FedExForum',
          city: 'Memphis',
          state: 'TN',
          country: 'USA',
          homeTeamId: 'NBA_MEM'
        },
        'NBA_NOP': {
          id: 'SMOOTHIE_KING_CENTER',
          name: 'Smoothie King Center',
          city: 'New Orleans',
          state: 'LA',
          country: 'USA',
          homeTeamId: 'NBA_NOP'
        },
        'NBA_SAS': {
          id: 'AT_T_CENTER',
          name: 'AT&T Center',
          city: 'San Antonio',
          state: 'TX',
          country: 'USA',
          homeTeamId: 'NBA_SAS'
        },
        'NBA_OKC': {
          id: 'PAYCOM_CENTER',
          name: 'Paycom Center',
          city: 'Oklahoma City',
          state: 'OK',
          country: 'USA',
          homeTeamId: 'NBA_OKC'
        },
        'NBA_MIN': {
          id: 'TARGET_CENTER',
          name: 'Target Center',
          city: 'Minneapolis',
          state: 'MN',
          country: 'USA',
          homeTeamId: 'NBA_MIN'
        }
      };

      // Update games with venue objects
      const updateStmt = db.prepare(`
        UPDATE games 
        SET venue = ?
        WHERE home_team_id = ?
      `);

      Object.entries(venueMap).forEach(([teamId, venue]) => {
        const venueJson = JSON.stringify(venue);
        updateStmt.run(venueJson, teamId, (err) => {
          if (err) {
            console.error(`Error updating games for team ${teamId}:`, err);
          } else {
            console.log(`✓ Updated games for team ${teamId} with venue ${venue.name}`);
          }
        });
      });

      updateStmt.finalize();

      console.log('Games venue population completed!');
      resolve();
    });
  });
};

// Run population if called directly
if (require.main === module) {
  populateGamesWithVenues()
    .then(() => {
      console.log('Games venue population completed successfully');
      db.close();
      process.exit(0);
    })
    .catch((error) => {
      console.error('Games venue population failed:', error);
      db.close();
      process.exit(1);
    });
}

module.exports = { populateGamesWithVenues };
