const sqlite3 = require('sqlite3').verbose();
const config = require('../config');

// Create database connection
const db = new sqlite3.Database(config.dbPath);

const populateRosters = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      console.log('Populating rosters...');

      // Sample roster IDs for NBA teams
      const rosterIds = [
        'NBA_GSW_ROSTER_2024',
        'NBA_LAC_ROSTER_2024',
        'NBA_LAL_ROSTER_2024',
        'NBA_PHX_ROSTER_2024',
        'NBA_DEN_ROSTER_2024',
        'NBA_UTA_ROSTER_2024',
        'NBA_POR_ROSTER_2024',
        'NBA_SAC_ROSTER_2024',
        'NBA_BOS_ROSTER_2024',
        'NBA_MIA_ROSTER_2024',
        'NBA_NYK_ROSTER_2024',
        'NBA_BKN_ROSTER_2024',
        'NBA_PHI_ROSTER_2024',
        'NBA_TOR_ROSTER_2024',
        'NBA_CHI_ROSTER_2024',
        'NBA_CLE_ROSTER_2024',
        'NBA_DET_ROSTER_2024',
        'NBA_IND_ROSTER_2024',
        'NBA_MIL_ROSTER_2024',
        'NBA_ATL_ROSTER_2024',
        'NBA_CHA_ROSTER_2024',
        'NBA_ORL_ROSTER_2024',
        'NBA_WAS_ROSTER_2024',
        'NBA_DAL_ROSTER_2024',
        'NBA_HOU_ROSTER_2024',
        'NBA_MEM_ROSTER_2024',
        'NBA_NOP_ROSTER_2024',
        'NBA_SAS_ROSTER_2024',
        'NBA_OKC_ROSTER_2024',
        'NBA_MIN_ROSTER_2024'
      ];

      const stmt = db.prepare(`
        INSERT OR IGNORE INTO rosters (id)
        VALUES (?)
      `);

      rosterIds.forEach(rosterId => {
        stmt.run(rosterId, (err) => {
          if (err) {
            console.error(`Error inserting roster ${rosterId}:`, err);
          } else {
            console.log(`✓ Created roster: ${rosterId}`);
          }
        });
      });

      stmt.finalize();

      // Update teams with roster IDs
      const teamRosterMap = {
        'NBA_GSW': 'NBA_GSW_ROSTER_2024',
        'NBA_LAC': 'NBA_LAC_ROSTER_2024',
        'NBA_LAL': 'NBA_LAL_ROSTER_2024',
        'NBA_PHX': 'NBA_PHX_ROSTER_2024',
        'NBA_DEN': 'NBA_DEN_ROSTER_2024',
        'NBA_UTA': 'NBA_UTA_ROSTER_2024',
        'NBA_POR': 'NBA_POR_ROSTER_2024',
        'NBA_SAC': 'NBA_SAC_ROSTER_2024',
        'NBA_BOS': 'NBA_BOS_ROSTER_2024',
        'NBA_MIA': 'NBA_MIA_ROSTER_2024',
        'NBA_NYK': 'NBA_NYK_ROSTER_2024',
        'NBA_BKN': 'NBA_BKN_ROSTER_2024',
        'NBA_PHI': 'NBA_PHI_ROSTER_2024',
        'NBA_TOR': 'NBA_TOR_ROSTER_2024',
        'NBA_CHI': 'NBA_CHI_ROSTER_2024',
        'NBA_CLE': 'NBA_CLE_ROSTER_2024',
        'NBA_DET': 'NBA_DET_ROSTER_2024',
        'NBA_IND': 'NBA_IND_ROSTER_2024',
        'NBA_MIL': 'NBA_MIL_ROSTER_2024',
        'NBA_ATL': 'NBA_ATL_ROSTER_2024',
        'NBA_CHA': 'NBA_CHA_ROSTER_2024',
        'NBA_ORL': 'NBA_ORL_ROSTER_2024',
        'NBA_WAS': 'NBA_WAS_ROSTER_2024',
        'NBA_DAL': 'NBA_DAL_ROSTER_2024',
        'NBA_HOU': 'NBA_HOU_ROSTER_2024',
        'NBA_MEM': 'NBA_MEM_ROSTER_2024',
        'NBA_NOP': 'NBA_NOP_ROSTER_2024',
        'NBA_SAS': 'NBA_SAS_ROSTER_2024',
        'NBA_OKC': 'NBA_OKC_ROSTER_2024',
        'NBA_MIN': 'NBA_MIN_ROSTER_2024'
      };

      const updateStmt = db.prepare(`
        UPDATE teams 
        SET roster_id = ?
        WHERE id = ?
      `);

      Object.entries(teamRosterMap).forEach(([teamId, rosterId]) => {
        updateStmt.run(rosterId, teamId, (err) => {
          if (err) {
            console.error(`Error updating team ${teamId} with roster ${rosterId}:`, err);
          } else {
            console.log(`✓ Updated team ${teamId} with roster ${rosterId}`);
          }
        });
      });

      updateStmt.finalize();

      console.log('Roster population completed!');
      resolve();
    });
  });
};

// Run population if called directly
if (require.main === module) {
  populateRosters()
    .then(() => {
      console.log('Roster population completed successfully');
      db.close();
      process.exit(0);
    })
    .catch((error) => {
      console.error('Roster population failed:', error);
      db.close();
      process.exit(1);
    });
}

module.exports = { populateRosters };
