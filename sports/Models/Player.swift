//
//  Player.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct Player: Identifiable, Codable {
    let id: String
    let teamId: String
    let displayName: String
    let firstName: String
    let lastName: String
    let jerseyNumber: Int?
    let position: String?
    let birthdate: String?
    let age: Int?
    let heightInches: Int?
    let heightFormatted: String?
    let weightLbs: Int?
    let weightFormatted: String?
    let nationality: String?
    let college: String?
    let photoUrl: String?
    let injuryStatus: String?
    let draftYear: Int?
    let draftPickOverall: Int?
    let active: Bool
    let apiPlayerId: Int?
    let team: Team?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, teamId, displayName, firstName, lastName, jerseyNumber
        case position, birthdate, age
        case heightInches, heightFormatted, weightLbs, weightFormatted
        case nationality, college, photoUrl, injuryStatus, draftYear, draftPickOverall
        case active, apiPlayerId, team, createdAt, updatedAt
    }
    
    init(id: String, teamId: String, displayName: String, firstName: String, lastName: String, jerseyNumber: Int? = nil, position: String? = nil, birthdate: String? = nil, age: Int? = nil, heightInches: Int? = nil, heightFormatted: String? = nil, weightLbs: Int? = nil, weightFormatted: String? = nil, nationality: String? = nil, college: String? = nil, photoUrl: String? = nil, injuryStatus: String? = nil, draftYear: Int? = nil, draftPickOverall: Int? = nil, active: Bool = true, apiPlayerId: Int? = nil, team: Team? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.teamId = teamId
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.jerseyNumber = jerseyNumber
        self.position = position
        self.birthdate = birthdate
        self.age = age
        self.heightInches = heightInches
        self.heightFormatted = heightFormatted
        self.weightLbs = weightLbs
        self.weightFormatted = weightFormatted
        self.nationality = nationality
        self.college = college
        self.photoUrl = photoUrl
        self.injuryStatus = injuryStatus
        self.draftYear = draftYear
        self.draftPickOverall = draftPickOverall
        self.active = active
        self.apiPlayerId = apiPlayerId
        self.team = team
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        teamId = try container.decode(String.self, forKey: .teamId)
        displayName = try container.decode(String.self, forKey: .displayName)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        jerseyNumber = try container.decodeIfPresent(Int.self, forKey: .jerseyNumber)
        position = try container.decodeIfPresent(String.self, forKey: .position)
        birthdate = try container.decodeIfPresent(String.self, forKey: .birthdate)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        heightInches = try container.decodeIfPresent(Int.self, forKey: .heightInches)
        heightFormatted = try container.decodeIfPresent(String.self, forKey: .heightFormatted)
        weightLbs = try container.decodeIfPresent(Int.self, forKey: .weightLbs)
        weightFormatted = try container.decodeIfPresent(String.self, forKey: .weightFormatted)
        nationality = try container.decodeIfPresent(String.self, forKey: .nationality)
        college = try container.decodeIfPresent(String.self, forKey: .college)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        injuryStatus = try container.decodeIfPresent(String.self, forKey: .injuryStatus)
        draftYear = try container.decodeIfPresent(Int.self, forKey: .draftYear)
        draftPickOverall = try container.decodeIfPresent(Int.self, forKey: .draftPickOverall)
        active = try container.decode(Bool.self, forKey: .active)
        apiPlayerId = try container.decodeIfPresent(Int.self, forKey: .apiPlayerId)
        team = try container.decodeIfPresent(Team.self, forKey: .team)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(jerseyNumber, forKey: .jerseyNumber)
        try container.encodeIfPresent(position, forKey: .position)
        try container.encode(birthdate, forKey: .birthdate)
        try container.encode(age, forKey: .age)
        try container.encode(heightInches, forKey: .heightInches)
        try container.encode(heightFormatted, forKey: .heightFormatted)
        try container.encode(weightLbs, forKey: .weightLbs)
        try container.encode(weightFormatted, forKey: .weightFormatted)
        try container.encodeIfPresent(nationality, forKey: .nationality)
        try container.encodeIfPresent(college, forKey: .college)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(injuryStatus, forKey: .injuryStatus)
        try container.encodeIfPresent(draftYear, forKey: .draftYear)
        try container.encodeIfPresent(draftPickOverall, forKey: .draftPickOverall)
        try container.encode(active, forKey: .active)
        try container.encodeIfPresent(apiPlayerId, forKey: .apiPlayerId)
        try container.encodeIfPresent(team, forKey: .team)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    
    /// Returns the full name of the player
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    /// Returns the position string with secondary position if available
    var positionString: String {
        return position ?? "Unknown"
    }
    
    /// Returns true if the player is injured
    var isInjured: Bool {
        return injuryStatus != nil && injuryStatus != "Healthy"
    }
    
    /// Returns true if the player is available to play
    var isAvailable: Bool {
        return active && !isInjured
    }
    
    /// Returns the age as a string, or "Unknown" if not available
    var ageString: String {
        return age.map { "\($0)" } ?? "Unknown"
    }
    
    /// Returns the height as a string, or "Unknown" if not available
    var heightString: String {
        return heightFormatted ?? "Unknown"
    }
    
    /// Returns the weight as a string, or "Unknown" if not available
    var weightString: String {
        return weightFormatted ?? "Unknown"
    }
    
    /// Returns the draft information as a formatted string
    var draftInfo: String? {
        guard let year = draftYear, let pick = draftPickOverall else { return nil }
        return "\(year) - Pick #\(pick)"
    }
    
    /// Returns the nationality with flag emoji if available
    var nationalityWithFlag: String {
        guard let nationality = nationality else { return "Unknown" }
        
        // Simple flag mapping for common countries
        let flagMap: [String: String] = [
            "USA": "🇺🇸",
            "Canada": "🇨🇦",
            "Australia": "🇦🇺",
            "France": "🇫🇷",
            "Germany": "🇩🇪",
            "Spain": "🇪🇸",
            "Italy": "🇮🇹",
            "Serbia": "🇷🇸",
            "Croatia": "🇭🇷",
            "Slovenia": "🇸🇮",
            "Greece": "🇬🇷",
            "Turkey": "🇹🇷",
            "Brazil": "🇧🇷",
            "Argentina": "🇦🇷",
            "Mexico": "🇲🇽",
            "Nigeria": "🇳🇬",
            "Senegal": "🇸🇳",
            "Congo": "🇨🇬",
            "Cameroon": "🇨🇲",
            "South Sudan": "🇸🇸",
            "Lithuania": "🇱🇹",
            "Latvia": "🇱🇻",
            "Estonia": "🇪🇪",
            "Poland": "🇵🇱",
            "Czech Republic": "🇨🇿",
            "Slovakia": "🇸🇰",
            "Russia": "🇷🇺",
            "Ukraine": "🇺🇦",
            "Georgia": "🇬🇪",
            "Israel": "🇮🇱",
            "Japan": "🇯🇵",
            "China": "🇨🇳",
            "Philippines": "🇵🇭",
            "New Zealand": "🇳🇿"
        ]
        
        let flag = flagMap[nationality] ?? "🌍"
        return "\(flag) \(nationality)"
    }
}
