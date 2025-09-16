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
    let season: String
    let isActive: Bool
}

enum Sport: String, Codable, CaseIterable {
    case football = "football"
    case basketball = "basketball"
    case baseball = "baseball"
    case hockey = "hockey"
    case soccer = "soccer"
    case volleyball = "volleyball"
    case olympic = "olympic"
}

enum LeagueLevel: String, Codable, CaseIterable {
    case professional = "professional"
    case college = "college"
    case olympic = "olympic"
}
