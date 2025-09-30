//
//  Player.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct Player: Identifiable, Codable {
    let id: String
    let name: String
    let firstName: String
    let lastName: String
    let jerseyNumber: Int?
    let position: String
    let height: String?
    let weight: Int?
    let age: Int?
    let birthDate: Date?
    let birthPlace: String?
    let currentTeam: Team?
    let headshotURL: String?
    let isActive: Bool
    
    // Career statistics
    let careerStats: [String: Any] // TODO:QUESTION - Define specific stat structure per sport
    
    enum CodingKeys: String, CodingKey {
        case id, name, firstName, lastName, jerseyNumber, position
        case height, weight, age, birthDate, birthPlace, currentTeam
        case headshotURL, isActive, careerStats
    }
    
    init(id: String, name: String, firstName: String, lastName: String, jerseyNumber: Int? = nil, position: String, height: String? = nil, weight: Int? = nil, age: Int? = nil, birthDate: Date? = nil, birthPlace: String? = nil, currentTeam: Team? = nil, headshotURL: String? = nil, isActive: Bool = true, careerStats: [String: Any] = [:]) {
        self.id = id
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.jerseyNumber = jerseyNumber
        self.position = position
        self.height = height
        self.weight = weight
        self.age = age
        self.birthDate = birthDate
        self.birthPlace = birthPlace
        self.currentTeam = currentTeam
        self.headshotURL = headshotURL
        self.isActive = isActive
        self.careerStats = careerStats
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        jerseyNumber = try container.decodeIfPresent(Int.self, forKey: .jerseyNumber)
        position = try container.decode(String.self, forKey: .position)
        height = try container.decodeIfPresent(String.self, forKey: .height)
        weight = try container.decodeIfPresent(Int.self, forKey: .weight)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        birthDate = try container.decodeIfPresent(Date.self, forKey: .birthDate)
        birthPlace = try container.decodeIfPresent(String.self, forKey: .birthPlace)
        currentTeam = try container.decodeIfPresent(Team.self, forKey: .currentTeam)
        headshotURL = try container.decodeIfPresent(String.self, forKey: .headshotURL)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        careerStats = [:] // TODO: Implement proper stat decoding
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(jerseyNumber, forKey: .jerseyNumber)
        try container.encode(position, forKey: .position)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(birthPlace, forKey: .birthPlace)
        try container.encodeIfPresent(currentTeam, forKey: .currentTeam)
        try container.encodeIfPresent(headshotURL, forKey: .headshotURL)
        try container.encode(isActive, forKey: .isActive)
        // TODO: Implement proper stat encoding
    }
}
