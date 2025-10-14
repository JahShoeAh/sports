# Database Schema Migration Guide

This guide outlines the database schema changes made to implement better normalization and add new features.

## Changes Made

### 1. New Tables

#### Players Table
- **Purpose**: Store individual player information
- **Columns**: 
  - `id` (TEXT PRIMARY KEY)
  - `team_id` (TEXT NOT NULL, FK to teams)
  - `display_name` (TEXT NOT NULL)
  - `first_name` (TEXT NOT NULL)
  - `last_name` (TEXT NOT NULL)
  - `jersey_number` (INTEGER)
  - `primary_position` (TEXT NOT NULL)
  - `secondary_position` (TEXT)
  - `birthdate` (TEXT NOT NULL)
  - `height_inches` (INTEGER NOT NULL)
  - `weight_lbs` (INTEGER NOT NULL)
  - `nationality` (TEXT)
  - `photo_url` (TEXT)
  - `injury_status` (TEXT)
  - `draft_year` (INTEGER)
  - `draft_pick_overall` (INTEGER)
  - `active` (INTEGER NOT NULL DEFAULT 1)
  - `created_at` (DATETIME)
  - `updated_at` (DATETIME)

#### Venues Table (Updated)
- **Purpose**: Store venue information separately from games
- **Columns**:
  - `id` (TEXT PRIMARY KEY)
  - `name` (TEXT NOT NULL)
  - `city` (TEXT, nullable)
  - `state` (TEXT, nullable) 
  - `country` (TEXT, nullable)
  - `home_team_id` (TEXT, nullable, FK to teams)
  - `created_at` (DATETIME)
  - `updated_at` (DATETIME)

### 2. Updated Tables

#### Teams Table
- **Removed**: `roster_id` (no longer needed - players link directly to teams)
- **Purpose**: Teams now have direct relationship with players via team_id

#### Games Table
- **Removed**: `time_remaining`, `city`, `state`, `country`
- **Kept**: `venue_id` (already existed)
- **Purpose**: Venue location info now comes from venues table via JOIN

### 3. Swift Models Updated

#### Team Model
- **Removed**: `rosterId: String?` (no longer needed)

#### Game Model  
- **Removed**: `timeRemaining`, `gameStats`, `city`, `state`, `country`
- **Added**: `venueId: String?`

#### New Models
- **Player**: Complete player model with all attributes
- **Venue**: `id`, `name`, `city?`, `state?`, `country?`, `homeTeamId?`

## Migration Steps

### 1. Run Database Migration
```bash
cd server
node scripts/migrate-schema.js
```

### 2. Populate Sample Data
```bash
# Populate players
node scripts/seed-nba-players.js

# Populate venues  
node scripts/populate-venues.js
```

### 3. Update Existing Data
After migration, you may need to:
- Update existing games to link to proper venue IDs

## API Changes

### New Endpoints
- `GET /api/players` - List all players (with optional filtering)
- `GET /api/players/:id` - Get specific player
- `GET /api/players/team/:teamId` - Get team roster
- `GET /api/venues` - List all venues
- `GET /api/venues/:id` - Get specific venue
- `POST /api/venues` - Create new venue

### Updated Responses
- Team objects no longer include `rosterId` field
- Game objects now include `venueId` field and remove location fields
- Player information is available via separate API calls
- Venue information is available via separate API calls

## Benefits of Changes

### 1. Normalization
- **Data Consistency**: Venue info stored once, referenced by games
- **Storage Efficiency**: No duplicate venue data across games
- **Update Efficiency**: Change venue info in one place

### 2. Flexibility
- **Player Management**: Players can be managed independently with full details
- **Venue Management**: Venues can be managed independently
- **Future Extensions**: Easy to add more player/venue properties

### 3. Performance
- **Smaller Game Records**: Removed redundant location data
- **Better Queries**: Can JOIN venue data when needed
- **Indexing**: Better performance with normalized structure

## Potential Issues & Solutions

### 1. Breaking Changes
- **iOS App**: Will need to handle missing fields gracefully
- **API Clients**: May need updates for new response format
- **Solution**: Gradual rollout with backward compatibility

### 2. Data Migration
- **Existing Games**: May lose venue location if not properly migrated
- **Solution**: Run migration scripts and verify data integrity

### 3. Performance Impact
- **JOIN Queries**: More complex queries for complete game data
- **Solution**: Proper indexing and query optimization

### 4. Null Values
- **Player Data**: Some optional fields may be null initially
- **Venue Data**: Some fields may be null initially
- **Solution**: Handle gracefully in UI, populate as data becomes available

## Testing

### 1. Database Integrity
```sql
-- Check for orphaned references
SELECT * FROM games WHERE venue_id NOT IN (SELECT id FROM venues);
SELECT * FROM players WHERE team_id NOT IN (SELECT id FROM teams);

-- Verify data counts
SELECT COUNT(*) FROM players;
SELECT COUNT(*) FROM venues;
SELECT COUNT(*) FROM teams;
```

### 2. API Testing
```bash
# Test new endpoints
curl http://localhost:3000/api/players
curl http://localhost:3000/api/players/team/NBA_LAL
curl http://localhost:3000/api/venues
curl http://localhost:3000/api/games?leagueId=NBA
```

### 3. iOS App Testing
- Verify app handles missing fields gracefully
- Test new player/roster functionality
- Ensure game display still works correctly

## Rollback Plan

If issues arise, you can rollback by:
1. Restore from database backup
2. Revert code changes
3. Re-run old migration scripts

## Future Enhancements

### Player Table Extensions
- Add player statistics
- Add season information
- Add contract information

### Venue Table Extensions  
- Add capacity information
- Add venue amenities
- Add venue images/descriptions

### Performance Optimizations
- Add composite indexes
- Implement caching for frequently accessed data
- Consider read replicas for heavy query loads
