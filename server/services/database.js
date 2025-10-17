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
        (id, homeTeamId, awayTeamId, leagueId, season, week, gameTime,
         venueId, homeScore, awayScore, homeLineScore, awayLineScore, leadChanges,
         quarter, isLive, isCompleted, apiGameId, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `);
      
      stmt.run([
        game.id,
        game.homeTeamId,
        game.awayTeamId,
        game.leagueId,
        game.season,
        game.week,
        game.gameTime,
        game.venueId || null,
        game.homeScore,
        game.awayScore,
        Array.isArray(game.homeLineScore) ? JSON.stringify(game.homeLineScore) : null,
        Array.isArray(game.awayLineScore) ? JSON.stringify(game.awayLineScore) : null,
        typeof game.leadChanges === 'number' ? game.leadChanges : null,
        game.quarter,
        game.isLive,
        game.isCompleted,
        game.apiGameId ?? null
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
        SELECT g.id, g.homeTeamId, g.awayTeamId, g.leagueId, g.season, g.week, g.gameTime,
               g.venueId, g.homeScore, g.awayScore, g.homeLineScore, g.awayLineScore, g.leadChanges,
               g.quarter, g.isLive, g.isCompleted, g.apiGameId,
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
      
      query += ' ORDER BY g.gameTime DESC';
      
      this.db.all(query, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  async getSeasons(leagueId) {
    return new Promise((resolve, reject) => {
      this.db.all(
        'SELECT DISTINCT season FROM games WHERE leagueId = ? ORDER BY season',
        [leagueId],
        (err, rows) => {
          if (err) {
            reject(err);
          } else {
            resolve(rows.map(r => r.season));
          }
        }
      );
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
        (id, teamId, displayName, firstName, lastName, jerseyNumber, position,
         birthdate, heightInches, weightLbs, nationality, college, photoUrl,
         injuryStatus, draftYear, draftPickOverall, active, apiPlayerId, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `);
      
      stmt.run([
        player.id,
        player.teamId,
        player.displayName,
        player.firstName,
        player.lastName,
        player.jerseyNumber,
        player.position || null,
        player.birthdate,
        player.heightInches,
        player.weightLbs,
        player.nationality || null,
        player.college || null,
        player.photoUrl || null,
        player.injuryStatus || null,
        player.draftYear || null,
        player.draftPickOverall || null,
        player.active ? 1 : 0,
        player.apiPlayerId ?? null
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
        WHERE p.position = ?
      `;
      
      const params = [position];
      
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

  // PlayerStats operations
  async savePlayerStats(stats) {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO playerStats 
        (gameId, playerId, teamId, points, pos, min, fgm, fga, fgp, ftm, fta, ftp,
         tpm, tpa, tpp, offReb, defReb, totReb, assists, pFouls, steals, turnovers,
         blocks, plusMinus, comment, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `);
      
      stmt.run([
        stats.gameId,
        stats.playerId,
        stats.teamId,
        stats.points || 0,
        stats.pos || null,
        stats.min || null,
        stats.fgm || 0,
        stats.fga || 0,
        stats.fgp || null,
        stats.ftm || 0,
        stats.fta || 0,
        stats.ftp || null,
        stats.tpm || 0,
        stats.tpa || 0,
        stats.tpp || null,
        stats.offReb || 0,
        stats.defReb || 0,
        stats.totReb || 0,
        stats.assists || 0,
        stats.pFouls || 0,
        stats.steals || 0,
        stats.turnovers || 0,
        stats.blocks || 0,
        stats.plusMinus || null,
        stats.comment || null
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

  async getPlayerStats(gameId, playerId) {
    return new Promise((resolve, reject) => {
      this.db.get(`
        SELECT ps.*, p.displayName, p.firstName, p.lastName, p.jerseyNumber, p.position,
               t.name as teamName, t.city as teamCity, t.abbreviation as teamAbbreviation,
               g.gameTime, g.homeTeamId, g.awayTeamId
        FROM playerStats ps
        LEFT JOIN players p ON ps.playerId = p.id
        LEFT JOIN teams t ON ps.teamId = t.id
        LEFT JOIN games g ON ps.gameId = g.id
        WHERE ps.gameId = ? AND ps.playerId = ?
      `, [gameId, playerId], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  async getPlayerStatsByGame(gameId) {
    return new Promise((resolve, reject) => {
      this.db.all(`
        SELECT ps.*, p.displayName, p.firstName, p.lastName, p.jerseyNumber, p.position,
               t.name as teamName, t.city as teamCity, t.abbreviation as teamAbbreviation,
               g.gameTime, g.homeTeamId, g.awayTeamId
        FROM playerStats ps
        LEFT JOIN players p ON ps.playerId = p.id
        LEFT JOIN teams t ON ps.teamId = t.id
        LEFT JOIN games g ON ps.gameId = g.id
        WHERE ps.gameId = ?
        ORDER BY t.name, p.jerseyNumber
      `, [gameId], (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  async getPlayerStatsByPlayer(playerId) {
    return new Promise((resolve, reject) => {
      this.db.all(`
        SELECT ps.*, p.displayName, p.firstName, p.lastName, p.jerseyNumber, p.position,
               t.name as teamName, t.city as teamCity, t.abbreviation as teamAbbreviation,
               g.gameTime, g.homeTeamId, g.awayTeamId
        FROM playerStats ps
        LEFT JOIN players p ON ps.playerId = p.id
        LEFT JOIN teams t ON ps.teamId = t.id
        LEFT JOIN games g ON ps.gameId = g.id
        WHERE ps.playerId = ?
        ORDER BY g.gameTime DESC
      `, [playerId], (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  async getPlayerStatsByTeam(teamId, gameId = null) {
    return new Promise((resolve, reject) => {
      let query = `
        SELECT ps.*, p.displayName, p.firstName, p.lastName, p.jerseyNumber, p.position,
               t.name as teamName, t.city as teamCity, t.abbreviation as teamAbbreviation,
               g.gameTime, g.homeTeamId, g.awayTeamId
        FROM playerStats ps
        LEFT JOIN players p ON ps.playerId = p.id
        LEFT JOIN teams t ON ps.teamId = t.id
        LEFT JOIN games g ON ps.gameId = g.id
        WHERE ps.teamId = ?
      `;
      
      const params = [teamId];
      
      if (gameId) {
        query += ' AND ps.gameId = ?';
        params.push(gameId);
      }
      
      query += ' ORDER BY g.gameTime DESC, p.jerseyNumber';
      
      this.db.all(query, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  async deletePlayerStats(gameId, playerId) {
    return new Promise((resolve, reject) => {
      this.db.run(
        'DELETE FROM playerStats WHERE gameId = ? AND playerId = ?',
        [gameId, playerId],
        function(err) {
          if (err) {
            reject(err);
          } else {
            resolve(this.changes);
          }
        }
      );
    });
  }

  async getStats() {
    return new Promise((resolve, reject) => {
      this.db.all(`
        SELECT 
          (SELECT COUNT(*) FROM leagues) as leaguesCount,
          (SELECT COUNT(*) FROM teams) as teamsCount,
          (SELECT COUNT(*) FROM games) as gamesCount,
          (SELECT COUNT(*) FROM playerStats) as playerStatsCount,
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
