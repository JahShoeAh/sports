const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
// Removed cron - no longer using scheduled data refresh

const config = require('./config');
const { initializeDatabase } = require('./database/setup');
// Removed dataRefresh - no longer using external APIs

// Import routes
const gamesRoutes = require('./routes/games');
const teamsRoutes = require('./routes/teams');
const leaguesRoutes = require('./routes/leagues');
const rostersRoutes = require('./routes/rosters');
const venuesRoutes = require('./routes/venues');

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
    res.json({
      success: true,
      data: {
        server: {
          status: 'running',
          uptime: process.uptime(),
          environment: config.nodeEnv,
          timestamp: new Date().toISOString()
        },
        message: 'Server running with static data - no external APIs'
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
app.use('/api/rosters', rostersRoutes);
app.use('/api/venues', venuesRoutes);

// Data refresh endpoint removed - using static data only

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
      console.log(`🏀 NBA Teams: http://localhost:${config.port}/api/teams?leagueId=NBA`);
      console.log(`🏈 NFL Teams: http://localhost:${config.port}/api/teams?leagueId=NFL`);
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

// Data refresh functionality removed - using static data only

// Start the application
if (require.main === module) {
  startServer();
}

module.exports = app;
