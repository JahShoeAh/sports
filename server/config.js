// Configuration file for the Sports API Server
module.exports = {
  // API Configuration - Removed external API dependencies
  
  // Server Configuration
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Database Configuration
  dbPath: './data/sports.db',
  
  // CORS Configuration
  allowedOrigins: [
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    // Add your iOS app's URL when deployed
  ],
  
  // Cron Schedule (3 AM EST = 8 AM UTC)
  cronSchedule: '0 8 * * *',
  
  // API Rate Limiting
  rateLimit: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
  },
  
  // Data refresh settings
  dataRefresh: {
    maxAge: 24 * 60 * 60 * 1000, // 24 hours in milliseconds
    retryAttempts: 3,
    retryDelay: 5000, // 5 seconds
    fetchOnStartup: process.env.FETCH_ON_STARTUP === 'true' || process.env.NODE_ENV !== 'production' // Fetch on startup if explicitly requested or in development
  }
};
