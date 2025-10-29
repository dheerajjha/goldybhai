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

// Import services
const rateFetcher = require('./services/rateFetcher');
const alertChecker = require('./services/alertChecker');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

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
  console.error('Server error:', err);
  res.status(500).json({
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

    // Start alert checker service
    console.log('🔔 Starting alert checker service...');
    alertChecker.start();

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
  const { closeDatabase } = require('./config/database');
  await closeDatabase();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  rateFetcher.stop();
  alertChecker.stop();
  const { closeDatabase } = require('./config/database');
  await closeDatabase();
  process.exit(0);
});

// Start the server
startServer();
