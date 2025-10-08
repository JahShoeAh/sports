# TheSportsDB API v1 Test Files

This directory contains test files to explore and test TheSportsDB API v1 before integrating it into your sports app server.

## Test Files

### 1. `test-thesportsdb.js`
**Basic API exploration and testing**
- Tests API connectivity
- Searches for NFL teams
- Searches for NFL games/events
- Gets all available leagues
- Tests events by date
- **Run with:** `npm run test:thesportsdb`

### 2. `test-nfl-specific.js`
**Focused NFL data fetching**
- Finds NFL league ID
- Gets all NFL teams
- Fetches NFL games for 2025 season
- Gets upcoming NFL games
- Saves results to JSON file
- **Run with:** `npm run test:nfl`

### 3. `test-thesportsdb-comprehensive.js`
**Complete comprehensive testing**
- Tests all major API endpoints
- Analyzes NFL data structure
- Gets 2025 season games
- Gets recent and upcoming games
- Saves detailed results to JSON file
- **Run with:** `npm run test:comprehensive`

## Quick Start

```bash
# Navigate to server directory
cd server

# Run individual tests
npm run test:thesportsdb    # Basic API tests
npm run test:nfl           # NFL-specific tests
npm run test:comprehensive # Full comprehensive test

# Run all tests (takes longer due to rate limits)
npm run test:all
```

## API Information

- **Base URL:** `https://www.thesportsdb.com/api/v1/json`
- **Free API Key:** `123`
- **Rate Limit:** 30 requests per minute (free tier)
- **Documentation:** https://www.thesportsdb.com/documentation

## Expected Results

The tests will help you understand:

1. **NFL League Structure**
   - How NFL leagues are organized in TheSportsDB
   - League IDs and naming conventions

2. **Team Data**
   - Available NFL team information
   - Team IDs, names, stadiums, badges
   - Data structure and completeness

3. **Game/Event Data**
   - How games are structured
   - Date formats and season naming
   - Available game information (scores, venues, etc.)

4. **API Limitations**
   - Rate limiting behavior
   - Data availability and quality
   - Response formats and error handling

## Output Files

Some tests will generate JSON files with results:
- `nfl-data-YYYY-MM-DD.json` - NFL-specific data
- `thesportsdb-test-results-YYYY-MM-DD.json` - Comprehensive test results

## Rate Limiting

The free API has a 30 requests per minute limit. The test files include:
- Automatic rate limiting with delays
- Request counting and waiting
- Graceful handling of rate limit errors

## Next Steps

After running these tests, you can:

1. **Analyze the results** to understand data structure
2. **Identify the best endpoints** for your app's needs
3. **Plan your server integration** based on the API capabilities
4. **Consider upgrading to premium** if you need higher rate limits or v2 API access

## Notes

- The free API key `123` is used for testing
- Some endpoints may have limited data in the free tier
- The 2025 NFL season data may be limited (season hasn't started yet)
- Consider the API's data freshness and update frequency for your app
