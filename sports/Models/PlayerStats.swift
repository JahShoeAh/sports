//
//  PlayerStats.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import Foundation

struct PlayerStats: Identifiable, Codable {
    let id: String
    let gameId: String
    let playerId: String
    let teamId: String
    let points: Int
    let pos: String
    let min: String
    let fgm: Int
    let fga: Int
    let fgp: String
    let ftm: Int
    let fta: Int
    let ftp: String
    let tpm: Int
    let tpa: Int
    let tpp: String
    let offReb: Int
    let defReb: Int
    let totReb: Int
    let assists: Int
    let pFouls: Int
    let steals: Int
    let turnovers: Int
    let blocks: Int
    let plusMinus: String
    let comment: String?
    let player: PlayerInfo
    let team: TeamInfo
    let game: GameInfo
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case gameId, playerId, teamId, points, pos, min
        case fgm, fga, fgp, ftm, fta, ftp, tpm, tpa, tpp
        case offReb, defReb, totReb, assists, pFouls
        case steals, turnovers, blocks, plusMinus, comment
        case player, team, game, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Generate id from composite key (gameId, playerId) since database uses composite primary key
        gameId = try container.decode(String.self, forKey: .gameId)
        playerId = try container.decode(String.self, forKey: .playerId)
        id = "\(gameId)_\(playerId)"
        teamId = try container.decode(String.self, forKey: .teamId)
        points = try container.decode(Int.self, forKey: .points)
        pos = try container.decode(String.self, forKey: .pos)
        min = try container.decode(String.self, forKey: .min)
        fgm = try container.decode(Int.self, forKey: .fgm)
        fga = try container.decode(Int.self, forKey: .fga)
        fgp = try container.decode(String.self, forKey: .fgp)
        ftm = try container.decode(Int.self, forKey: .ftm)
        fta = try container.decode(Int.self, forKey: .fta)
        ftp = try container.decode(String.self, forKey: .ftp)
        tpm = try container.decode(Int.self, forKey: .tpm)
        tpa = try container.decode(Int.self, forKey: .tpa)
        tpp = try container.decode(String.self, forKey: .tpp)
        offReb = try container.decode(Int.self, forKey: .offReb)
        defReb = try container.decode(Int.self, forKey: .defReb)
        totReb = try container.decode(Int.self, forKey: .totReb)
        assists = try container.decode(Int.self, forKey: .assists)
        pFouls = try container.decode(Int.self, forKey: .pFouls)
        steals = try container.decode(Int.self, forKey: .steals)
        turnovers = try container.decode(Int.self, forKey: .turnovers)
        blocks = try container.decode(Int.self, forKey: .blocks)
        plusMinus = try container.decode(String.self, forKey: .plusMinus)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        player = try container.decode(PlayerInfo.self, forKey: .player)
        team = try container.decode(TeamInfo.self, forKey: .team)
        game = try container.decode(GameInfo.self, forKey: .game)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // id is computed from composite key, not encoded
        try container.encode(gameId, forKey: .gameId)
        try container.encode(playerId, forKey: .playerId)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(points, forKey: .points)
        try container.encode(pos, forKey: .pos)
        try container.encode(min, forKey: .min)
        try container.encode(fgm, forKey: .fgm)
        try container.encode(fga, forKey: .fga)
        try container.encode(fgp, forKey: .fgp)
        try container.encode(ftm, forKey: .ftm)
        try container.encode(fta, forKey: .fta)
        try container.encode(ftp, forKey: .ftp)
        try container.encode(tpm, forKey: .tpm)
        try container.encode(tpa, forKey: .tpa)
        try container.encode(tpp, forKey: .tpp)
        try container.encode(offReb, forKey: .offReb)
        try container.encode(defReb, forKey: .defReb)
        try container.encode(totReb, forKey: .totReb)
        try container.encode(assists, forKey: .assists)
        try container.encode(pFouls, forKey: .pFouls)
        try container.encode(steals, forKey: .steals)
        try container.encode(turnovers, forKey: .turnovers)
        try container.encode(blocks, forKey: .blocks)
        try container.encode(plusMinus, forKey: .plusMinus)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(player, forKey: .player)
        try container.encode(team, forKey: .team)
        try container.encode(game, forKey: .game)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

struct PlayerInfo: Codable {
    let id: String
    let displayName: String
    let firstName: String
    let lastName: String
    let jerseyNumber: Int?
    let position: String?
}

struct TeamInfo: Codable {
    let id: String
    let name: String
    let city: String
    let abbreviation: String
}

struct GameInfo: Codable {
    let id: String
    let gameTime: String
    let homeTeamId: String
    let awayTeamId: String
}

// MARK: - Response Models
struct YourServerPlayerStatsResponse: Codable {
    let success: Bool
    let data: [PlayerStats]
    let count: Int
    let filters: PlayerStatsFilters?
}

struct PlayerStatsFilters: Codable {
    let gameId: String?
    let playerId: String?
    let teamId: String?
}
