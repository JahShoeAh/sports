const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const cron = require('node-cron');

const config = require('./config');
const { initializeDatabase } = require('./database/setup');
const dataRefresh = require('./services/dataRefresh');

// Import routes
const gamesRoutes = require('./routes/games');
const teamsRoutes = require('./routes/teams');
const leaguesRoutes = require('./routes/leagues');

const app = express();

// Security middleware
app.use(helmet());

// Compression middleware
app.use(compression());

// CORS middleware
app.use(cors({
  origin: config.allowedOrigins,
  credentials: true
}));

// Rate limiting
const limiter = rateLimit(config.rateLimit);
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`${timestamp} - ${req.method} ${req.path} - IP: ${req.ip}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: config.nodeEnv
  });
});

// API status endpoint
app.get('/api/status', async (req, res) => {
  try {
    const stats = await dataRefresh.getRefreshStatus();
    const apiTest = await dataRefresh.testApiConnection();
    
    res.json({
      success: true,
      data: {
        server: {
          status: 'running',
          uptime: process.uptime(),
          environment: config.nodeEnv,
          timestamp: new Date().toISOString()
        },
        database: stats.stats,
        apiConnection: apiTest,
        refreshStatus: {
          isRefreshing: stats.isRefreshing,
          lastRefresh: stats.lastRefresh
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error getting status',
      error: error.message
    });
  }
});

// API routes
app.use('/api/games', gamesRoutes);
app.use('/api/teams', teamsRoutes);
app.use('/api/leagues', leaguesRoutes);

// Global refresh endpoint
app.post('/api/refresh', async (req, res) => {
  try {
    const { leagueId = '1', season = '2025' } = req.body;
    
    const result = await dataRefresh.forceRefreshLeagueData(leagueId, season);
    
    res.json(result);

  } catch (error) {
    console.error('Error in global refresh:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.originalUrl
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: config.nodeEnv === 'development' ? error.message : 'Something went wrong'
  });
});

// Initialize database and start server
const startServer = async () => {
  try {
    console.log('Initializing database...');
    await initializeDatabase();
    console.log('Database initialized successfully');

    // Start the server
    const server = app.listen(config.port, () => {
      console.log(`🚀 Sports API Server running on port ${config.port}`);
      console.log(`📊 Environment: ${config.nodeEnv}`);
      console.log(`🔗 Health check: http://localhost:${config.port}/health`);
      console.log(`📈 API status: http://localhost:${config.port}/api/status`);
      console.log(`🏈 NFL Games: http://localhost:${config.port}/api/games?leagueId=1`);
      console.log(`👥 NFL Teams: http://localhost:${config.port}/api/teams?leagueId=1`);
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      console.log('SIGTERM received, shutting down gracefully');
      server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      console.log('SIGINT received, shutting down gracefully');
      server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    });

  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Schedule automatic data refresh
const scheduleDataRefresh = () => {
  console.log(`Scheduling data refresh with cron: ${config.cronSchedule}`);
  
  cron.schedule(config.cronSchedule, async () => {
    console.log('🔄 Starting scheduled data refresh...');
    
    try {
      const results = await dataRefresh.refreshAllData();
      console.log('✅ Scheduled data refresh completed:', results);
    } catch (error) {
      console.error('❌ Scheduled data refresh failed:', error);
    }
  }, {
    timezone: 'UTC'
  });
  
  console.log('✅ Data refresh scheduled successfully');
};

// Initial data fetch on startup
const initialDataFetch = async () => {
  // Only fetch on startup in development mode
  if (!config.dataRefresh.fetchOnStartup) {
    console.log('⏭️  Skipping initial data fetch (production mode)');
    return;
  }
  
  console.log('🔄 Starting initial data fetch...');
  
  try {
    // Check if we have any data first
    const stats = await dataRefresh.getRefreshStatus();
    
    if (!stats.stats.gamesCount || stats.stats.gamesCount === 0) {
      console.log('📊 No data found, fetching initial data...');
      const results = await dataRefresh.refreshAllData();
      console.log('✅ Initial data fetch completed:', results);
    } else {
      console.log('📊 Data already exists, skipping initial fetch');
      console.log(`   - Games: ${stats.stats.gamesCount}`);
      console.log(`   - Teams: ${stats.stats.teamsCount}`);
      console.log(`   - Leagues: ${stats.stats.leaguesCount}`);
    }
  } catch (error) {
    console.error('❌ Initial data fetch failed:', error);
  }
};

// Start the application
if (require.main === module) {
  startServer().then(async () => {
    // Fetch initial data on startup
    await initialDataFetch();
    
    // Schedule regular data refresh
    scheduleDataRefresh();
  });
}

module.exports = app;
