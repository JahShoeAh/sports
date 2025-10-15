const https = require('https');
const fs = require('fs');
const path = require('path');

// Game IDs to fetch
const gameIds = [12257, 12258, 12259, 12260, 12261, 12262, 12263, 12264];

// API configuration
const API_BASE_URL = 'https://v2.nba.api-sports.io/players/statistics';
const API_KEY = process.env.NBA_API_KEY || '9316aa1d2d0c2d55eb84b0dc566fc21a';

// Function to make API request
function fetchPlayerStats(gameId) {
    return new Promise((resolve, reject) => {
        const url = `${API_BASE_URL}?game=${gameId}`;
        
        const options = {
            headers: {
                'x-rapidapi-key': API_KEY,
                'x-rapidapi-host': 'v2.nba.api-sports.io'
            }
        };

        console.log(`Fetching stats for game ${gameId}...`);
        
        https.get(url, options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(data);
                    console.log(`Successfully fetched stats for game ${gameId}`);
                    resolve({
                        gameId: gameId,
                        data: jsonData,
                        timestamp: new Date().toISOString()
                    });
                } catch (error) {
                    console.error(`Error parsing JSON for game ${gameId}:`, error);
                    reject(error);
                }
            });
        }).on('error', (error) => {
            console.error(`Error fetching stats for game ${gameId}:`, error);
            reject(error);
        });
    });
}

// Function to add delay between requests to avoid rate limiting
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Main function to fetch all data
async function fetchAllPlayerStats() {
    const allStats = [];
    
    try {
        for (let i = 0; i < gameIds.length; i++) {
            const gameId = gameIds[i];
            
            try {
                const stats = await fetchPlayerStats(gameId);
                allStats.push(stats);
                
                // Add delay between requests (except for the last one)
                if (i < gameIds.length - 1) {
                    console.log('Waiting 1 second before next request...');
                    await delay(1000);
                }
            } catch (error) {
                console.error(`Failed to fetch stats for game ${gameId}:`, error);
                // Continue with other games even if one fails
            }
        }
        
        // Save to file
        const outputPath = path.join(__dirname, '..', 'raw_api', 'raw-stats-4-8.json');
        const outputData = {
            metadata: {
                totalGames: gameIds.length,
                fetchedAt: new Date().toISOString(),
                gameIds: gameIds
            },
            games: allStats
        };
        
        fs.writeFileSync(outputPath, JSON.stringify(outputData, null, 2));
        console.log(`\nSuccessfully saved all stats to: ${outputPath}`);
        console.log(`Fetched data for ${allStats.length} out of ${gameIds.length} games`);
        
    } catch (error) {
        console.error('Error in fetchAllPlayerStats:', error);
    }
}

// Run the script
console.log('Starting to fetch player statistics for 8 games...');
console.log('Game IDs:', gameIds);
console.log('');

fetchAllPlayerStats();
