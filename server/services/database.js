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
        (id, name, abbreviation, logo_url, sport, level, is_active, updated_at)
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
        (id, name, city, abbreviation, logo_url, league_id, conference, division, updated_at)
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
        'SELECT * FROM teams WHERE league_id = ? ORDER BY conference, division, name',
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
        SELECT t.*, l.name as league_name, l.abbreviation as league_abbreviation, 
               l.logo_url as league_logo_url, l.sport as league_sport, l.level as league_level, l.is_active as league_is_active
        FROM teams t
        LEFT JOIN leagues l ON t.league_id = l.id
        WHERE t.league_id = ?
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

  // Game operations
  async saveGame(game) {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO games 
        (id, home_team_id, away_team_id, league_id, season, week, game_date, game_time,
         venue_id, venue, city, state, country, home_score, away_score,
         quarter, time_remaining, is_live, is_completed, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
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
        game.venueId,
        game.venue,
        game.city,
        game.state,
        game.country,
        game.homeScore,
        game.awayScore,
        game.quarter,
        game.timeRemaining,
        game.isLive,
        game.isCompleted
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
        SELECT g.id, g.home_team_id, g.away_team_id, g.league_id, g.season, g.week, g.game_date, g.game_time,
               g.venue_id, g.venue, g.city, g.state, g.country, g.home_score, g.away_score,
               g.quarter, g.time_remaining, g.is_live, g.is_completed, g.created_at, g.updated_at,
               ht.name as home_team_name, ht.city as home_team_city, ht.abbreviation as home_team_abbr, ht.logo_url as home_team_logo, ht.conference as home_team_conference, ht.division as home_team_division,
               at.name as away_team_name, at.city as away_team_city, at.abbreviation as away_team_abbr, at.logo_url as away_team_logo, at.conference as away_team_conference, at.division as away_team_division,
               l.name as league_name, l.abbreviation as league_abbreviation, l.logo_url as league_logo_url, l.sport as league_sport, l.level as league_level, l.is_active as league_is_active
        FROM games g
        LEFT JOIN teams ht ON g.home_team_id = ht.id
        LEFT JOIN teams at ON g.away_team_id = at.id
        LEFT JOIN leagues l ON g.league_id = l.id
        WHERE g.league_id = ?
      `;
      
      const params = [leagueId];
      
      if (season) {
        query += ' AND g.season = ?';
        params.push(season);
      }
      
      query += ' ORDER BY g.game_date DESC, g.game_time DESC';
      
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
        INSERT OR REPLACE INTO data_freshness 
        (league_id, last_updated, last_successful_fetch, fetch_attempts, last_error)
        VALUES (?, CURRENT_TIMESTAMP, ?, 
                COALESCE((SELECT fetch_attempts FROM data_freshness WHERE league_id = ?), 0) + 1, ?)
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
        'SELECT * FROM data_freshness WHERE league_id = ?',
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
    if (!freshness || !freshness.last_successful_fetch) {
      return false;
    }
    
    const lastUpdate = new Date(freshness.last_successful_fetch);
    const now = new Date();
    return (now - lastUpdate) < maxAge;
  }

  // Utility methods
  async clearLeagueData(leagueId) {
    return new Promise((resolve, reject) => {
      this.db.serialize(() => {
        this.db.run('DELETE FROM games WHERE league_id = ?', [leagueId]);
        this.db.run('DELETE FROM teams WHERE league_id = ?', [leagueId]);
        this.db.run('DELETE FROM leagues WHERE id = ?', [leagueId]);
        this.db.run('DELETE FROM data_freshness WHERE league_id = ?', [leagueId], (err) => {
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
          (SELECT COUNT(*) FROM leagues) as leagues_count,
          (SELECT COUNT(*) FROM teams) as teams_count,
          (SELECT COUNT(*) FROM games) as games_count,
          (SELECT COUNT(*) FROM data_freshness) as freshness_count
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
