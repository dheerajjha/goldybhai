const { run, get } = require('../config/database');

let cleanupInterval = null;

/**
 * Delete rates older than 7 days
 */
async function cleanupOldData() {
  try {
    // Calculate date 7 days ago
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const cutoffDate = sevenDaysAgo.toISOString().replace('T', ' ').substring(0, 19);

    // Count old records
    const result = await get(
      'SELECT COUNT(*) as count FROM rates WHERE updated_at < ?',
      [cutoffDate]
    );

    const oldRecords = result?.count || 0;

    if (oldRecords > 0) {
      // Delete old rates
      await run('DELETE FROM rates WHERE updated_at < ?', [cutoffDate]);
      console.log(`🧹 Deleted ${oldRecords} old rate records (older than 7 days)`);
    } else {
      console.log('🧹 No old data to clean');
    }
  } catch (error) {
    console.error('❌ Cleanup error:', error.message);
  }
}

/**
 * Start cleanup - runs every 24 hours
 */
function start() {
  console.log('🧹 Data cleanup started (runs every 24 hours)');

  // Run every 24 hours (86400000 ms)
  cleanupInterval = setInterval(cleanupOldData, 24 * 60 * 60 * 1000);
}

/**
 * Stop cleanup
 */
function stop() {
  if (cleanupInterval) {
    clearInterval(cleanupInterval);
    console.log('🛑 Data cleanup stopped');
  }
}

module.exports = { start, stop };
