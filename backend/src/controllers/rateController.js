const { all, get } = require('../config/database');

/**
 * Get latest rates for all commodities
 */
async function getLatestRates(req, res) {
  try {
    const query = `
      SELECT
        r.id,
        r.commodity_id,
        c.name as commodity_name,
        c.symbol,
        c.unit,
        c.type,
        r.ltp,
        r.buy_price,
        r.sell_price,
        r.high,
        r.low,
        r.updated_at,
        r.source
      FROM commodities c
      LEFT JOIN (
        SELECT r1.*
        FROM rates r1
        INNER JOIN (
          SELECT commodity_id, MAX(updated_at) as max_date
          FROM rates
          GROUP BY commodity_id
        ) r2 ON r1.commodity_id = r2.commodity_id
           AND r1.updated_at = r2.max_date
      ) r ON c.id = r.commodity_id
      ORDER BY c.type, c.name
    `;

    const rates = await all(query);

    res.json({
      success: true,
      data: rates,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching latest rates:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch latest rates'
    });
  }
}

/**
 * Get rate history for a specific commodity
 */
async function getRateHistory(req, res) {
  try {
    const { commodityId } = req.params;
    const { limit = 100, offset = 0 } = req.query;

    // Verify commodity exists
    const commodity = await get(
      'SELECT * FROM commodities WHERE id = ?',
      [commodityId]
    );

    if (!commodity) {
      return res.status(404).json({
        success: false,
        error: 'Commodity not found'
      });
    }

    const rates = await all(
      `SELECT * FROM rates
       WHERE commodity_id = ?
       ORDER BY updated_at DESC
       LIMIT ? OFFSET ?`,
      [commodityId, parseInt(limit), parseInt(offset)]
    );

    res.json({
      success: true,
      data: {
        commodity,
        rates,
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset),
          total: rates.length
        }
      }
    });
  } catch (error) {
    console.error('Error fetching rate history:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch rate history'
    });
  }
}

/**
 * Get latest rate for a specific commodity
 */
async function getLatestRateByCommodity(req, res) {
  try {
    const { commodityId } = req.params;

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

    const rate = await get(query, [commodityId]);

    if (!rate) {
      return res.status(404).json({
        success: false,
        error: 'No rates found for this commodity'
      });
    }

    res.json({
      success: true,
      data: rate
    });
  } catch (error) {
    console.error('Error fetching commodity rate:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch commodity rate'
    });
  }
}

module.exports = {
  getLatestRates,
  getRateHistory,
  getLatestRateByCommodity
};
