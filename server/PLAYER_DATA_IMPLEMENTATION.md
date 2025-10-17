# Player Data Implementation

This document describes the implementation of player data for the NBA teams in the sports application.

## Overview

We have successfully implemented a complete player data system that includes:
- 360 unique players across 30 NBA teams (12 players per team)
- Comprehensive player attributes including physical stats, draft info, and injury status
- RESTful API endpoints for accessing player data
- Swift client models with helper methods for display formatting

## Database Schema

### Players Table

The `players` table includes the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `id` | TEXT PRIMARY KEY | Unique player identifier (e.g., "Player_One_1") |
| `team_id` | TEXT NOT NULL | Foreign key to teams table |
| `display_name` | TEXT NOT NULL | Display name (e.g., "Player One") |
| `first_name` | TEXT NOT NULL | First name |
| `last_name` | TEXT NOT NULL | Last name |
| `jersey_number` | INTEGER | Jersey number (1-12) |
| `primary_position` | TEXT NOT NULL | Primary position (G, F, C, G-F, F-C) |
| `secondary_position` | TEXT | Secondary position (optional) |
| `birthdate` | TEXT NOT NULL | Birth date in YYYY-MM-DD format |
| `height_inches` | INTEGER NOT NULL | Height in inches |
| `weight_lbs` | INTEGER NOT NULL | Weight in pounds |
| `nationality` | TEXT | Player's nationality |
| `photo_url` | TEXT | URL to player photo |
| `injury_status` | TEXT | Current injury status |
| `draft_year` | INTEGER | Year drafted |
| `draft_pick_overall` | INTEGER | Overall draft pick number |
| `active` | INTEGER | Whether player is active (1/0) |
| `created_at` | DATETIME | Creation timestamp |
| `updated_at` | DATETIME | Last update timestamp |

### Indexes

The following indexes are created for optimal performance:
- `idx_players_team` on `team_id`
- `idx_players_display_name` on `display_name`
- `idx_players_position` on `primary_position`
- `idx_players_active` on `active`

## Data Generation

### Player Naming Convention

Players are named using a systematic approach:
- **Display Name**: "Player One", "Player Two", ..., "Player Three Hundred Sixty"
- **First Name**: "Player"
- **Last Name**: "One", "Two", ..., "Three Hundred Sixty"
- **ID**: "Player_One_1", "Player_Two_2", etc.

### Position Distribution

Each team has 12 players with the following position distribution:
- 4 Guards (G)
- 4 Forwards (F)
- 2 Centers (C)
- 1 Guard-Forward (G-F)
- 1 Forward-Center (F-C)

### Physical Attributes

Height and weight are generated based on position:
- **Guards**: 70-78 inches, 170-220 lbs
- **Forwards**: 76-82 inches, 200-250 lbs
- **Centers**: 80-87 inches, 240-280 lbs
- **G-F**: 74-80 inches, 180-230 lbs
- **F-C**: 78-84 inches, 220-260 lbs

### Other Attributes

- **Age**: 19-38 years (calculated from birthdate)
- **Nationality**: Random selection from 33 countries
- **Injury Status**: Random selection from 6 statuses
- **Draft Info**: Random year (2015-2024), random pick (1-60)
- **Jersey Numbers**: 1-12 per team

## API Endpoints

### GET /api/players

Fetch players with optional filtering.

**Query Parameters:**
- `teamId` (optional): Filter by team
- `leagueId` (optional): Filter by league
- `position` (optional): Filter by position

**Response:**
```json
{
  "success": true,
  "data": [Player objects],
  "count": 360,
  "filters": {
    "teamId": null,
    "leagueId": "NBA",
    "position": null
  }
}
```

### GET /api/players/:id

Fetch a specific player by ID.

**Response:**
```json
{
  "success": true,
  "data": Player object
}
```

### GET /api/players/team/:teamId

Fetch all players for a specific team.

**Response:**
```json
{
  "success": true,
  "data": [Player objects],
  "dataByPosition": {
    "G": [Player objects],
    "F": [Player objects],
    "C": [Player objects]
  },
  "count": 12,
  "teamId": "NBA_LAL"
}
```

## Swift Client Implementation

### Player Model

The `Player` struct includes all database fields plus helper methods:

```swift
struct Player: Identifiable, Codable {
    let id: String
    let teamId: String
    let displayName: String
    let firstName: String
    let lastName: String
    let jerseyNumber: Int?
    let primaryPosition: String
    let secondaryPosition: String?
    let birthdate: String
    let age: Int
    let heightInches: Int
    let heightFormatted: String  // "6'3\""
    let weightLbs: Int
    let weightFormatted: String  // "225 lb"
    let nationality: String?
    let photoUrl: String?
    let injuryStatus: String?
    let draftYear: Int?
    let draftPickOverall: Int?
    let active: Bool
    let team: Team?
    let createdAt: String?
    let updatedAt: String?
}
```

### Helper Methods

- `fullName`: Returns "FirstName LastName"
- `positionString`: Returns "Primary/Secondary" or just "Primary"
- `isInjured`: Returns true if player has injury status other than "Healthy"
- `isAvailable`: Returns true if player is active and not injured
- `draftInfo`: Returns formatted draft information
- `nationalityWithFlag`: Returns nationality with flag emoji

### API Service

The `YourServerAPI` class includes methods for fetching player data:

```swift
func fetchPlayers(teamId: String?, leagueId: String?, position: String?) async throws -> [Player]
func fetchPlayer(playerId: String) async throws -> Player
func fetchTeamRoster(teamId: String) async throws -> [Player]
```

## Usage

### Seeding Data

To populate the database with player data:

```bash
cd server
node scripts/seed-nba-players.js
```

### Viewing Data

The team roster view automatically loads and displays players when viewing a team. Players are shown with:
- Profile photo (placeholder if not available)
- Name and position
- Jersey number
- Height and age
- Nationality with flag emoji
- Injury status (if applicable)

## Future Enhancements

Potential improvements for the player data system:

1. **Real Player Data**: Replace generated data with actual NBA player information
2. **Player Photos**: Add real player headshots
3. **Statistics**: Add career and season statistics
4. **Transactions**: Track player trades and signings
5. **Injury History**: Detailed injury tracking over time
6. **Social Media**: Links to player social media accounts
7. **Biography**: Player background and career highlights

## Files Modified

### Server Side
- `server/database/setup.js` - Added players table schema
- `server/services/database.js` - Added player database methods
- `server/routes/players.js` - New player API routes
- `server/server.js` - Added players route
- `server/scripts/seed-nba-players.js` - New seeding script

### Client Side
- `sports/Models/Player.swift` - Updated player model
- `sports/Services/YourServerAPI.swift` - Added player API methods
- `sports/Views/Team/TeamMenuView.swift` - Updated roster display

## Testing

The implementation has been tested with:
- Database seeding (360 players across 30 teams)
- API endpoints returning correct data
- Swift models properly decoding JSON responses
- UI displaying player information correctly

All endpoints return properly formatted JSON with appropriate HTTP status codes and error handling.
