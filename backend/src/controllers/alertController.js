const { all, get, run } = require('../config/database');

/**
 * Get all alerts for a user
 */
async function getAllAlerts(req, res) {
  try {
    const { userId = 1 } = req.query; // Default to user 1 (guest)

    const query = `
      SELECT
        a.*,
        c.name as commodity_name,
        c.symbol,
        c.unit,
        c.type
      FROM alerts a
      JOIN commodities c ON a.commodity_id = c.id
      WHERE a.user_id = ?
      ORDER BY a.created_at DESC
    `;

    const alerts = await all(query, [userId]);

    res.json({
      success: true,
      data: alerts
    });
  } catch (error) {
    console.error('Error fetching alerts:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch alerts'
    });
  }
}

/**
 * Get alert by ID
 */
async function getAlertById(req, res) {
  try {
    const { id } = req.params;

    const query = `
      SELECT
        a.*,
        c.name as commodity_name,
        c.symbol,
        c.unit,
        c.type
      FROM alerts a
      JOIN commodities c ON a.commodity_id = c.id
      WHERE a.id = ?
    `;

    const alert = await get(query, [id]);

    if (!alert) {
      return res.status(404).json({
        success: false,
        error: 'Alert not found'
      });
    }

    res.json({
      success: true,
      data: alert
    });
  } catch (error) {
    console.error('Error fetching alert:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch alert'
    });
  }
}

/**
 * Create a new alert
 */
async function createAlert(req, res) {
  try {
    const { userId = 1, commodityId, condition, targetPrice } = req.body;

    // Validate required fields
    if (!commodityId || !condition || !targetPrice) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: commodityId, condition, targetPrice'
      });
    }

    // Validate condition
    if (!['<', '>'].includes(condition)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid condition. Must be "<" or ">"'
      });
    }

    // Verify commodity exists
    const commodity = await get(
      'SELECT id FROM commodities WHERE id = ?',
      [commodityId]
    );

    if (!commodity) {
      return res.status(404).json({
        success: false,
        error: 'Commodity not found'
      });
    }

    // Create alert
    const result = await run(
      `INSERT INTO alerts (user_id, commodity_id, condition, target_price, active)
       VALUES (?, ?, ?, ?, 1)`,
      [userId, commodityId, condition, parseFloat(targetPrice)]
    );

    // Fetch the created alert
    const newAlert = await get(
      `SELECT
         a.*,
         c.name as commodity_name,
         c.symbol,
         c.unit,
         c.type
       FROM alerts a
       JOIN commodities c ON a.commodity_id = c.id
       WHERE a.id = ?`,
      [result.lastID]
    );

    res.status(201).json({
      success: true,
      data: newAlert,
      message: 'Alert created successfully'
    });
  } catch (error) {
    console.error('Error creating alert:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to create alert'
    });
  }
}

/**
 * Update an alert
 */
async function updateAlert(req, res) {
  try {
    const { id } = req.params;
    const { condition, targetPrice, active } = req.body;

    // Verify alert exists
    const existing = await get('SELECT id FROM alerts WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: 'Alert not found'
      });
    }

    // Build update query dynamically
    const updates = [];
    const params = [];

    if (condition !== undefined) {
      if (!['<', '>'].includes(condition)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid condition. Must be "<" or ">"'
        });
      }
      updates.push('condition = ?');
      params.push(condition);
    }

    if (targetPrice !== undefined) {
      updates.push('target_price = ?');
      params.push(parseFloat(targetPrice));
    }

    if (active !== undefined) {
      updates.push('active = ?');
      params.push(active ? 1 : 0);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update'
      });
    }

    params.push(id);

    await run(
      `UPDATE alerts SET ${updates.join(', ')} WHERE id = ?`,
      params
    );

    // Fetch updated alert
    const updatedAlert = await get(
      `SELECT
         a.*,
         c.name as commodity_name,
         c.symbol,
         c.unit,
         c.type
       FROM alerts a
       JOIN commodities c ON a.commodity_id = c.id
       WHERE a.id = ?`,
      [id]
    );

    res.json({
      success: true,
      data: updatedAlert,
      message: 'Alert updated successfully'
    });
  } catch (error) {
    console.error('Error updating alert:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to update alert'
    });
  }
}

/**
 * Delete an alert
 */
async function deleteAlert(req, res) {
  try {
    const { id } = req.params;

    // Verify alert exists
    const existing = await get('SELECT id FROM alerts WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: 'Alert not found'
      });
    }

    await run('DELETE FROM alerts WHERE id = ?', [id]);

    res.json({
      success: true,
      message: 'Alert deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting alert:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to delete alert'
    });
  }
}

/**
 * Get active alerts
 */
async function getActiveAlerts(req, res) {
  try {
    const { userId = 1 } = req.query;

    const query = `
      SELECT
        a.*,
        c.name as commodity_name,
        c.symbol,
        c.unit,
        c.type
      FROM alerts a
      JOIN commodities c ON a.commodity_id = c.id
      WHERE a.user_id = ? AND a.active = 1 AND a.triggered_at IS NULL
      ORDER BY a.created_at DESC
    `;

    const alerts = await all(query, [userId]);

    res.json({
      success: true,
      data: alerts
    });
  } catch (error) {
    console.error('Error fetching active alerts:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch active alerts'
    });
  }
}

module.exports = {
  getAllAlerts,
  getAlertById,
  createAlert,
  updateAlert,
  deleteAlert,
  getActiveAlerts
};
