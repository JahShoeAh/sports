# Database Schema Migration Guide

This guide outlines the database schema changes made to implement better normalization and add new features.

## Changes Made

### 1. New Tables

#### Rosters Table
- **Purpose**: Store roster information that can change frequently
- **Columns**: 
  - `id` (TEXT PRIMARY KEY)
  - `created_at` (DATETIME)
  - `updated_at` (DATETIME)
- **Future**: Can be extended with player lists, season info, etc.

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
- **Added**: `roster_id` (TEXT, nullable, FK to rosters)
- **Purpose**: Link teams to their current roster

#### Games Table
- **Removed**: `time_remaining`, `city`, `state`, `country`
- **Kept**: `venue_id` (already existed)
- **Purpose**: Venue location info now comes from venues table via JOIN

### 3. Swift Models Updated

#### Team Model
- **Added**: `rosterId: String?`

#### Game Model  
- **Removed**: `timeRemaining`, `gameStats`, `city`, `state`, `country`
- **Added**: `venueId: String?`

#### New Models
- **Venue**: `id`, `name`, `city?`, `state?`, `country?`, `homeTeamId?`
- **Roster**: `id` (extensible for future features)

## Migration Steps

### 1. Run Database Migration
```bash
cd server
node scripts/migrate-schema.js
```

### 2. Populate Sample Data
```bash
# Populate rosters
node scripts/populate-rosters.js

# Populate venues  
node scripts/populate-venues.js
```

### 3. Update Existing Data
After migration, you may need to:
- Update existing games to link to proper venue IDs
- Assign roster IDs to teams as they become available

## API Changes

### New Endpoints
- `GET /api/rosters` - List all rosters
- `GET /api/rosters/:id` - Get specific roster
- `POST /api/rosters` - Create new roster
- `GET /api/venues` - List all venues
- `GET /api/venues/:id` - Get specific venue
- `POST /api/venues` - Create new venue

### Updated Responses
- Team objects now include `rosterId` field
- Game objects now include `venueId` field and remove location fields
- Venue information is available via separate API calls

## Benefits of Changes

### 1. Normalization
- **Data Consistency**: Venue info stored once, referenced by games
- **Storage Efficiency**: No duplicate venue data across games
- **Update Efficiency**: Change venue info in one place

### 2. Flexibility
- **Roster Management**: Teams can easily update rosters without affecting games
- **Venue Management**: Venues can be managed independently
- **Future Extensions**: Easy to add more roster/venue properties

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
- **Roster IDs**: Initially null for all teams
- **Venue Data**: Some fields may be null initially
- **Solution**: Handle gracefully in UI, populate as data becomes available

## Testing

### 1. Database Integrity
```sql
-- Check for orphaned references
SELECT * FROM games WHERE venue_id NOT IN (SELECT id FROM venues);
SELECT * FROM teams WHERE roster_id NOT IN (SELECT id FROM rosters);

-- Verify data counts
SELECT COUNT(*) FROM rosters;
SELECT COUNT(*) FROM venues;
SELECT COUNT(*) FROM teams WHERE roster_id IS NOT NULL;
```

### 2. API Testing
```bash
# Test new endpoints
curl http://localhost:3000/api/rosters
curl http://localhost:3000/api/venues
curl http://localhost:3000/api/games?leagueId=NBA
```

### 3. iOS App Testing
- Verify app handles missing fields gracefully
- Test new venue/roster functionality
- Ensure game display still works correctly

## Rollback Plan

If issues arise, you can rollback by:
1. Restore from database backup
2. Revert code changes
3. Re-run old migration scripts

## Future Enhancements

### Roster Table Extensions
- Add player lists
- Add season information
- Add roster statistics

### Venue Table Extensions  
- Add capacity information
- Add venue amenities
- Add venue images/descriptions

### Performance Optimizations
- Add composite indexes
- Implement caching for frequently accessed data
- Consider read replicas for heavy query loads
