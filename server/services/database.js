const sqlite3 = require('sqlite3').verbose();
const config = require('../config');

class DatabaseService {
  constructor() {
    this.db = new sqlite3.Database(config.dbPath);
  }

  // League operations
  async saveLeague(league) {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO leagues 
        (id, name, abbreviation, logoUrl, sport, level, isActive, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `);
      
      stmt.run([
        league.id,
        league.name,
        league.abbreviation,
        league.logoURL,
        league.sport,
        league.level,
        league.isActive
      ], function(err) {
        if (err) {
          reject(err);
        } else {
          resolve(this.lastID);
        }
      });
      
      stmt.finalize();
    });
  }

  async getLeagues() {
    return new Promise((resolve, reject) => {
      this.db.all('SELECT * FROM leagues ORDER BY name', (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  async getLeague(leagueId) {
    return new Promise((resolve, reject) => {
      this.db.get('SELECT * FROM leagues WHERE id = ?', [leagueId], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  // Team operations
  async saveTeam(team) {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO teams 
        (id, name, city, abbreviation, logoUrl, leagueId, conference, division, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `);
      
      stmt.run([
        team.id,
        team.name,
        team.city,
        team.abbreviation,
        team.logoURL,
        team.leagueId,
        team.conference,
        team.division
      ], function(err) {
        if (err) {
          reject(err);
        } else {
          resolve(this.lastID);
        }
      });
      
      stmt.finalize();
    });
  }

  async getTeams(leagueId) {
    return new Promise((resolve, reject) => {
      this.db.all(
        'SELECT * FROM teams WHERE leagueId = ? ORDER BY conference, division, name',
        [leagueId],
        (err, rows) => {
          if (err) {
            reject(err);
          } else {
            resolve(rows);
          }
        }
      );
    });
  }

  async getTeamsWithLeague(leagueId) {
    return new Promise((resolve, reject) => {
      this.db.all(`
        SELECT t.*, l.name as leagueName, l.abbreviation as leagueAbbreviation, 
               l.logoUrl as leagueLogoUrl, l.sport as leagueSport, l.level as leagueLevel, l.isActive as leagueIsActive
        FROM teams t
        LEFT JOIN leagues l ON t.leagueId = l.id
        WHERE t.leagueId = ?
        ORDER BY t.conference, t.division, t.name
      `, [leagueId], (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }


  // Venue operations
  async saveVenue(venue) {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO venues 
        (id, name, city, state, country, homeTeamId, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `);
      
      stmt.run([
        venue.id,
        venue.name,
        venue.city || null,
        venue.state || null,
        venue.country || null,
        venue.homeTeamId || null
      ], function(err) {
        if (err) {
          reject(err);
        } else {
          resolve(this.lastID);
        }
      });
      
      stmt.finalize();
    });
  }

  async getVenue(venueId) {
    return new Promise((resolve, reject) => {
      this.db.get('SELECT * FROM venues WHERE id = ?', [venueId], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  async getVenues() {
    return new Promise((resolve, reject) => {
      this.db.all('SELECT * FROM venues ORDER BY name', (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  // Game operations
  async saveGame(game) {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO games 
        (id, homeTeamId, awayTeamId, leagueId, season, week, gameDate, gameTime,
         venueId, homeScore, awayScore, quarter, isLive, isCompleted, boxScore, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `);
      
      stmt.run([
        game.id,
        game.homeTeamId,
        game.awayTeamId,
        game.leagueId,
        game.season,
        game.week,
        game.gameDate,
        game.gameTime,
        game.venueId || null,
        game.homeScore,
        game.awayScore,
        game.quarter,
        game.isLive,
        game.isCompleted,
        game.boxScore ? JSON.stringify(game.boxScore) : null
      ], function(err) {
        if (err) {
          reject(err);
        } else {
          resolve(this.lastID);
        }
      });
      
      stmt.finalize();
    });
  }

  async getGames(leagueId, season = null) {
    return new Promise((resolve, reject) => {
      let query = `
        SELECT g.id, g.homeTeamId, g.awayTeamId, g.leagueId, g.season, g.week, g.gameDate, g.gameTime,
               g.venueId, g.homeScore, g.awayScore, g.quarter, g.isLive, g.isCompleted, g.boxScore,
               g.createdAt, g.updatedAt,
               ht.name as homeTeamName, ht.city as homeTeamCity, ht.abbreviation as homeTeamAbbr, 
               ht.logoUrl as homeTeamLogo, ht.conference as homeTeamConference, ht.division as homeTeamDivision,
               at.name as awayTeamName, at.city as awayTeamCity, at.abbreviation as awayTeamAbbr, 
               at.logoUrl as awayTeamLogo, at.conference as awayTeamConference, at.division as awayTeamDivision,
               l.name as leagueName, l.abbreviation as leagueAbbreviation, l.logoUrl as leagueLogoUrl, 
               l.sport as leagueSport, l.level as leagueLevel, l.isActive as leagueIsActive,
               v.id as venueId, v.name as venueName, v.city as venueCity, v.state as venueState, 
               v.country as venueCountry, v.homeTeamId as venueHomeTeamId
        FROM games g
        LEFT JOIN teams ht ON g.homeTeamId = ht.id
        LEFT JOIN teams at ON g.awayTeamId = at.id
        LEFT JOIN leagues l ON g.leagueId = l.id
        LEFT JOIN venues v ON g.venueId = v.id
        WHERE g.leagueId = ?
      `;
      
      const params = [leagueId];
      
      if (season) {
        query += ' AND g.season = ?';
        params.push(season);
      }
      
      query += ' ORDER BY g.gameDate DESC, g.gameTime DESC';
      
      this.db.all(query, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  // Data freshness operations
  async updateDataFreshness(leagueId, success = true, error = null) {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO dataFreshness 
        (leagueId, lastUpdated, lastSuccessfulFetch, fetchAttempts, lastError)
        VALUES (?, CURRENT_TIMESTAMP, ?, 
                COALESCE((SELECT fetchAttempts FROM dataFreshness WHERE leagueId = ?), 0) + 1, ?)
      `);
      
      stmt.run([
        leagueId,
        success ? new Date().toISOString() : null,
        leagueId,
        error
      ], function(err) {
        if (err) {
          reject(err);
        } else {
          resolve(this.lastID);
        }
      });
      
      stmt.finalize();
    });
  }

  async getDataFreshness(leagueId) {
    return new Promise((resolve, reject) => {
      this.db.get(
        'SELECT * FROM dataFreshness WHERE leagueId = ?',
        [leagueId],
        (err, row) => {
          if (err) {
            reject(err);
          } else {
            resolve(row);
          }
        }
      );
    });
  }

  async isDataFresh(leagueId, maxAge = 24 * 60 * 60 * 1000) {
    const freshness = await this.getDataFreshness(leagueId);
    if (!freshness || !freshness.lastSuccessfulFetch) {
      return false;
    }
    
    const lastUpdate = new Date(freshness.lastSuccessfulFetch);
    const now = new Date();
    return (now - lastUpdate) < maxAge;
  }

  // Player operations
  async savePlayer(player) {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO players 
        (id, teamId, displayName, firstName, lastName, jerseyNumber, primaryPosition, 
         secondaryPosition, birthdate, heightInches, weightLbs, nationality, photoUrl, 
         injuryStatus, draftYear, draftPickOverall, active, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `);
      
      stmt.run([
        player.id,
        player.teamId,
        player.displayName,
        player.firstName,
        player.lastName,
        player.jerseyNumber,
        player.primaryPosition,
        player.secondaryPosition || null,
        player.birthdate,
        player.heightInches,
        player.weightLbs,
        player.nationality || null,
        player.photoUrl || null,
        player.injuryStatus || null,
        player.draftYear || null,
        player.draftPickOverall || null,
        player.active ? 1 : 0
      ], function(err) {
        if (err) {
          reject(err);
        } else {
          resolve(this.lastID);
        }
      });
      
      stmt.finalize();
    });
  }

  async getPlayer(playerId) {
    return new Promise((resolve, reject) => {
      this.db.get(`
        SELECT p.*, t.name as teamName, t.city as teamCity, t.abbreviation as teamAbbreviation,
               t.logoUrl as teamLogoUrl, t.conference as teamConference, t.division as teamDivision
        FROM players p
        LEFT JOIN teams t ON p.teamId = t.id
        WHERE p.id = ?
      `, [playerId], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  async getPlayers(teamId = null, leagueId = null) {
    return new Promise((resolve, reject) => {
      let query = `
        SELECT p.*, t.name as teamName, t.city as teamCity, t.abbreviation as teamAbbreviation,
               t.logoUrl as teamLogoUrl, t.conference as teamConference, t.division as teamDivision
        FROM players p
        LEFT JOIN teams t ON p.teamId = t.id
        WHERE 1=1
      `;
      
      const params = [];
      
      if (teamId) {
        query += ' AND p.teamId = ?';
        params.push(teamId);
      }
      
      if (leagueId) {
        query += ' AND t.leagueId = ?';
        params.push(leagueId);
      }
      
      query += ' ORDER BY t.name, p.jerseyNumber, p.lastName';
      
      this.db.all(query, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  async getTeamRoster(teamId) {
    return new Promise((resolve, reject) => {
      this.db.all(`
        SELECT p.*, t.name as teamName, t.city as teamCity, t.abbreviation as teamAbbreviation,
               t.logoUrl as teamLogoUrl, t.conference as teamConference, t.division as teamDivision
        FROM players p
        LEFT JOIN teams t ON p.teamId = t.id
        WHERE p.teamId = ? AND p.active = 1
        ORDER BY p.jerseyNumber, p.lastName
      `, [teamId], (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  async getPlayersByPosition(position, leagueId = null) {
    return new Promise((resolve, reject) => {
      let query = `
        SELECT p.*, t.name as teamName, t.city as teamCity, t.abbreviation as teamAbbreviation,
               t.logoUrl as teamLogoUrl, t.conference as teamConference, t.division as teamDivision
        FROM players p
        LEFT JOIN teams t ON p.teamId = t.id
        WHERE p.primaryPosition = ? OR p.secondaryPosition = ?
      `;
      
      const params = [position, position];
      
      if (leagueId) {
        query += ' AND t.leagueId = ?';
        params.push(leagueId);
      }
      
      query += ' ORDER BY t.name, p.jerseyNumber';
      
      this.db.all(query, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  // Utility methods
  async clearPlayers() {
    return new Promise((resolve, reject) => {
      this.db.run('DELETE FROM players', (err) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  }
  async clearLeagueData(leagueId) {
    return new Promise((resolve, reject) => {
      this.db.serialize(() => {
        this.db.run('DELETE FROM games WHERE leagueId = ?', [leagueId]);
        this.db.run('DELETE FROM teams WHERE leagueId = ?', [leagueId]);
        this.db.run('DELETE FROM leagues WHERE id = ?', [leagueId]);
        this.db.run('DELETE FROM dataFreshness WHERE leagueId = ?', [leagueId], (err) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      });
    });
  }

  async getStats() {
    return new Promise((resolve, reject) => {
      this.db.all(`
        SELECT 
          (SELECT COUNT(*) FROM leagues) as leaguesCount,
          (SELECT COUNT(*) FROM teams) as teamsCount,
          (SELECT COUNT(*) FROM games) as gamesCount,
          (SELECT COUNT(*) FROM dataFreshness) as freshnessCount
      `, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows[0]);
        }
      });
    });
  }

  close() {
    this.db.close();
  }
}

module.exports = new DatabaseService();
