//
//  Team.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct Team: Identifiable, Codable {
    let id: String
    let name: String
    let city: String
    let abbreviation: String
    let logoURL: String?
    let league: League
    let conference: String?
    let division: String?
    let colors: TeamColors?
    
    var fullName: String {
        return "\(city) \(name)"
    }
}

struct TeamColors: Codable {
    let primary: String
    let secondary: String
    let accent: String?
}

struct League: Identifiable, Codable {
    let id: String
    let name: String
    let abbreviation: String
    let logoURL: String?
    let sport: Sport
    let level: LeagueLevel
    let isActive: Bool
    
    init(id: String, name: String, abbreviation: String, logoURL: String?, sport: Sport, level: LeagueLevel, isActive: Bool) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.logoURL = logoURL
        self.sport = sport
        self.level = level
        self.isActive = isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        abbreviation = try container.decode(String.self, forKey: .abbreviation)
        logoURL = try container.decodeIfPresent(String.self, forKey: .logoURL)
        sport = try container.decode(Sport.self, forKey: .sport)
        level = try container.decode(LeagueLevel.self, forKey: .level)
        
        // Handle isActive as either Bool or Int from server
        if let boolValue = try? container.decode(Bool.self, forKey: .isActive) {
            isActive = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isActive) {
            isActive = intValue != 0
        } else {
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(
                codingPath: decoder.codingPath + [CodingKeys.isActive],
                debugDescription: "Expected to decode Bool or Int for isActive"
            ))
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, abbreviation, logoURL, sport, level, isActive
    }
}

enum Sport: String, Codable, CaseIterable {
    case football = "football"
    case basketball = "basketball"
    case baseball = "baseball"
    case hockey = "hockey"
    case soccer = "soccer"
    case volleyball = "volleyball"
    case olympic = "olympic"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Handle case variations from server
        switch rawValue.lowercased() {
        case "football":
            self = .football
        case "basketball":
            self = .basketball
        case "baseball":
            self = .baseball
        case "hockey":
            self = .hockey
        case "soccer":
            self = .soccer
        case "volleyball":
            self = .volleyball
        case "olympic":
            self = .olympic
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot initialize Sport from invalid String value \(rawValue)"
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

enum LeagueLevel: String, Codable, CaseIterable {
    case professional = "professional"
    case college = "college"
    case olympic = "olympic"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Handle case variations from server
        switch rawValue.lowercased() {
        case "professional":
            self = .professional
        case "college":
            self = .college
        case "olympic":
            self = .olympic
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot initialize LeagueLevel from invalid String value \(rawValue)"
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
