const { all, get, run } = require('../config/database');

// GOLD 999 WITH GST commodity ID (hardcoded for focus)
const GOLD999_COMMODITY_ID = 2;

/**
 * Get current LTP for GOLD 999 (ultra-lightweight)
 */
async function getCurrentLTP(req, res) {
  try {
    // Get latest rate
    const currentRate = await get(
      `SELECT ltp, updated_at 
       FROM rates 
       WHERE commodity_id = ? 
       ORDER BY updated_at DESC 
       LIMIT 1`,
      [GOLD999_COMMODITY_ID]
    );

    if (!currentRate) {
      return res.status(404).json({
        success: false,
        error: 'No rates available for GOLD 999'
      });
    }

    // Get previous rate for change calculation
    const previousRate = await get(
      `SELECT ltp 
       FROM rates 
       WHERE commodity_id = ? 
         AND updated_at < ? 
       ORDER BY updated_at DESC 
       LIMIT 1`,
      [GOLD999_COMMODITY_ID, currentRate.updated_at]
    );

    let change = 0;
    let changePercent = 0;

    if (previousRate) {
      change = currentRate.ltp - previousRate.ltp;
      changePercent = (change / previousRate.ltp) * 100;
    }

    res.json({
      success: true,
      ltp: currentRate.ltp,
      updated_at: currentRate.updated_at,
      change: parseFloat(change.toFixed(2)),
      change_percent: parseFloat(changePercent.toFixed(2))
    });
  } catch (error) {
    console.error('Error fetching current LTP:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch current LTP'
    });
  }
}

/**
 * Get chart data for last 1 hour with 1-minute intervals
 * Returns raw data points for accurate 1-hour chart
 */
async function getLastHourData(req, res) {
  try {
    // SQLite datetime format: 'YYYY-MM-DD HH:MM:SS'
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000)
      .toISOString()
      .replace('T', ' ')
      .substring(0, 19);
    
    const query = `
      SELECT 
        ltp,
        updated_at,
        strftime('%Y-%m-%d %H:%M:00', updated_at) as time_bucket
      FROM rates
      WHERE commodity_id = ?
        AND updated_at >= ?
      GROUP BY time_bucket
      ORDER BY updated_at ASC
    `;
    
    const data = await all(query, [GOLD999_COMMODITY_ID, oneHourAgo]);
    
    res.json({
      success: true,
      data: data.map(row => ({
        ltp: row.ltp,
        timestamp: row.updated_at,
        time: row.time_bucket
      })),
      interval: '1m',
      period: '1h',
      count: data.length
    });
  } catch (error) {
    console.error('Error fetching last hour data:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
}

/**
 * Get chart data for GOLD 999 with aggregation
 * Supports: realtime, hourly, daily intervals
 */
async function getChartData(req, res) {
  try {
    const { interval = 'hourly', days = 7, limit = 50 } = req.query;
    const daysInt = Math.min(parseInt(days) || 7, 30); // Max 30 days
    const limitInt = Math.min(parseInt(limit) || 50, 200); // Max 200 points

    // Get commodity info
    const commodity = await get(
      'SELECT id, name, symbol FROM commodities WHERE id = ?',
      [GOLD999_COMMODITY_ID]
    );

    if (!commodity) {
      return res.status(404).json({
        success: false,
        error: 'GOLD 999 commodity not found'
      });
    }

    // Calculate date range - SQLite format
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysInt);
    // SQLite datetime format: 'YYYY-MM-DD HH:MM:SS'
    const cutoffISO = cutoffDate.toISOString().replace('T', ' ').substring(0, 19);

    let query;
    let groupBy;

    if (interval === 'realtime') {
      // Return raw data points (last N points)
      query = `
        SELECT 
          ltp,
          updated_at as timestamp,
          ltp as min,
          ltp as max
        FROM rates
        WHERE commodity_id = ? 
          AND updated_at >= ?
        ORDER BY updated_at DESC
        LIMIT ?
      `;
      groupBy = null;
    } else if (interval === 'hourly') {
      // Aggregate by hour - SQLite datetime functions
      query = `
        SELECT 
          strftime('%Y-%m-%d %H:00:00', updated_at) as timestamp,
          AVG(ltp) as ltp,
          MIN(ltp) as min,
          MAX(ltp) as max,
          COUNT(*) as count
        FROM rates
        WHERE commodity_id = ? 
          AND updated_at >= ?
        GROUP BY strftime('%Y-%m-%d %H:00:00', updated_at)
        ORDER BY timestamp DESC
        LIMIT ?
      `;
    } else if (interval === 'daily') {
      // Aggregate by day
      query = `
        SELECT 
          strftime('%Y-%m-%d', updated_at) as timestamp,
          AVG(ltp) as ltp,
          MIN(ltp) as min,
          MAX(ltp) as max,
          COUNT(*) as count
        FROM rates
        WHERE commodity_id = ? 
          AND updated_at >= ?
        GROUP BY strftime('%Y-%m-%d', updated_at)
        ORDER BY timestamp DESC
        LIMIT ?
      `;
    } else {
      return res.status(400).json({
        success: false,
        error: 'Invalid interval. Use: realtime, hourly, or daily'
      });
    }

    const results = await all(query, [GOLD999_COMMODITY_ID, cutoffISO, limitInt]);

    // Format response
    const data = results
      .reverse() // Reverse to show chronological order (oldest first)
      .map(row => ({
        timestamp: row.timestamp,
        ltp: parseFloat(row.ltp.toFixed(2)),
        min: row.min ? parseFloat(row.min.toFixed(2)) : null,
        max: row.max ? parseFloat(row.max.toFixed(2)) : null,
        count: row.count || 1 // Number of data points in this aggregation
      }));

    // Get current rate for comparison
    const currentRate = await get(
      `SELECT ltp, updated_at 
       FROM rates 
       WHERE commodity_id = ? 
       ORDER BY updated_at DESC 
       LIMIT 1`,
      [GOLD999_COMMODITY_ID]
    );

    res.json({
      success: true,
      commodity: {
        id: commodity.id,
        name: commodity.name,
        symbol: commodity.symbol
      },
      data: data,
      current: currentRate ? {
        ltp: parseFloat(currentRate.ltp.toFixed(2)),
        updated_at: currentRate.updated_at
      } : null,
      metadata: {
        interval: interval,
        points: data.length,
        period: `${daysInt} days`,
        total_points: data.reduce((sum, point) => sum + (point.count || 1), 0)
      }
    });
  } catch (error) {
    console.error('Error fetching chart data:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch chart data'
    });
  }
}

/**
 * Get latest rate details for GOLD 999
 */
async function getLatestRate(req, res) {
  try {
    const query = `
      SELECT
        r.*,
        c.name as commodity_name,
        c.symbol,
        c.unit,
        c.type
      FROM rates r
      JOIN commodities c ON r.commodity_id = c.id
      WHERE r.commodity_id = ?
      ORDER BY r.updated_at DESC
      LIMIT 1
    `;

    const rate = await get(query, [GOLD999_COMMODITY_ID]);

    if (!rate) {
      return res.status(404).json({
        success: false,
        error: 'No rates found for GOLD 999'
      });
    }

    res.json({
      success: true,
      data: rate
    });
  } catch (error) {
    console.error('Error fetching latest rate:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch latest rate'
    });
  }
}

module.exports = {
  getCurrentLTP,
  getChartData,
  getLastHourData,
  getLatestRate,
  GOLD999_COMMODITY_ID
};

