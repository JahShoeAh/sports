//
//  Venue.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct Venue: Identifiable, Codable {
    let id: String
    let name: String
    let city: String?
    let state: String?
    let country: String?
    let homeTeamId: String?
    
    var fullLocation: String {
        var location = name
        if let city = city {
            location += ", \(city)"
        }
        if let state = state {
            location += ", \(state)"
        }
        if let country = country {
            location += ", \(country)"
        }
        return location
    }
}
