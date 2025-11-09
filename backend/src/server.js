require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const { initDatabase } = require('./config/database');
const migrate = require('./database/migrate');
const seed = require('./database/seed');

// Import routes
const commoditiesRouter = require('./routes/commodities');
const ratesRouter = require('./routes/rates');
const alertsRouter = require('./routes/alerts');
const preferencesRouter = require('./routes/preferences');
const gold999Router = require('./routes/gold999');
const fcmRouter = require('./routes/fcm');

// Import services
const rateFetcher = require('./services/rateFetcher');
const alertChecker = require('./services/alertChecker');
const fcmService = require('./services/fcmService');
const dataCleanup = require('./services/dataCleanup');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// URI error handler middleware - must be before routes
app.use((req, res, next) => {
  try {
    // Attempt to decode the URI to catch malformed URLs early
    decodeURIComponent(req.path);
    next();
  } catch (err) {
    // Log malicious/malformed requests at debug level to reduce noise
    console.log('Blocked malformed URI request:', req.path);
    return res.status(400).json({
      success: false,
      error: 'Invalid URI'
    });
  }
});

// Serve static files from web directory
app.use(express.static(path.join(__dirname, '../web')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API routes
app.use('/api/commodities', commoditiesRouter);
app.use('/api/rates', ratesRouter);
app.use('/api/alerts', alertsRouter);
app.use('/api/preferences', preferencesRouter);
app.use('/api/gold999', gold999Router);
app.use('/api/fcm', fcmRouter);

// 404 handler for API routes
app.use('/api/*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Serve web app for all non-API routes (must be last)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../web/index.html'));
});

// Error handler
app.use((err, req, res, next) => {
  // Handle URI decoding errors (malicious requests)
  if (err instanceof URIError || (err.message && err.message.includes('Failed to decode'))) {
    console.log('Blocked malformed URI request:', req.path);
    return res.status(400).json({
      success: false,
      error: 'Invalid URI'
    });
  }

  // Handle other errors
  console.error('Server error:', err);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Internal server error'
  });
});

// Initialize application
async function startServer() {
  try {
    console.log('🚀 Starting Shop Rates Backend...');

    // Initialize database
    await initDatabase();
    console.log('✅ Database connected');

    // Run migrations
    await migrate();
    console.log('✅ Migrations completed');

    // Seed initial data
    await seed();
    console.log('✅ Initial data seeded');

    // Reinitialize database after migrations/seeding (they close the connection)
    await initDatabase();
    console.log('✅ Database reconnected');

    // Start rate fetcher service
    console.log('📡 Starting rate fetcher service...');
    rateFetcher.start();

    // Initialize Firebase Admin SDK (for FCM)
    fcmService.initializeFirebase();

    // Start alert checker service
    console.log('🔔 Starting alert checker service...');
    alertChecker.start();

    // Start data cleanup service
    console.log('🧹 Starting data cleanup service...');
    dataCleanup.start();

    // Start server
    app.listen(PORT, () => {
      console.log(`\n✨ Server running on http://localhost:${PORT}`);
      console.log(`🌐 Web App: http://localhost:${PORT}`);
      console.log(`📊 API Documentation: http://localhost:${PORT}/health\n`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  rateFetcher.stop();
  alertChecker.stop();
  dataCleanup.stop();
  const { closeDatabase } = require('./config/database');
  await closeDatabase();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  rateFetcher.stop();
  alertChecker.stop();
  dataCleanup.stop();
  const { closeDatabase } = require('./config/database');
  await closeDatabase();
  process.exit(0);
});

// Start the server
startServer();
