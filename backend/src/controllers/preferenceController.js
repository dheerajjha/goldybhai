const { get, run } = require('../config/database');

/**
 * Get user preferences
 */
async function getPreferences(req, res) {
  try {
    const { userId = 1 } = req.query; // Default to user 1 (guest)

    const preferences = await get(
      'SELECT * FROM preferences WHERE user_id = ?',
      [userId]
    );

    if (!preferences) {
      return res.status(404).json({
        success: false,
        error: 'Preferences not found for this user'
      });
    }

    res.json({
      success: true,
      data: preferences
    });
  } catch (error) {
    console.error('Error fetching preferences:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch preferences'
    });
  }
}

/**
 * Update user preferences
 */
async function updatePreferences(req, res) {
  try {
    const { userId = 1 } = req.query;
    const { refreshInterval, currency, notificationsOn, theme } = req.body;

    // Verify preferences exist
    const existing = await get(
      'SELECT id FROM preferences WHERE user_id = ?',
      [userId]
    );

    if (!existing) {
      return res.status(404).json({
        success: false,
        error: 'Preferences not found for this user'
      });
    }

    // Build update query dynamically
    const updates = [];
    const params = [];

    if (refreshInterval !== undefined) {
      updates.push('refresh_interval = ?');
      params.push(parseInt(refreshInterval));
    }

    if (currency !== undefined) {
      updates.push('currency = ?');
      params.push(currency);
    }

    if (notificationsOn !== undefined) {
      updates.push('notifications_on = ?');
      params.push(notificationsOn ? 1 : 0);
    }

    if (theme !== undefined) {
      if (!['light', 'dark', 'system'].includes(theme)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid theme. Must be: light, dark, or system'
        });
      }
      updates.push('theme = ?');
      params.push(theme);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update'
      });
    }

    params.push(userId);

    await run(
      `UPDATE preferences SET ${updates.join(', ')} WHERE user_id = ?`,
      params
    );

    // Fetch updated preferences
    const updatedPreferences = await get(
      'SELECT * FROM preferences WHERE user_id = ?',
      [userId]
    );

    res.json({
      success: true,
      data: updatedPreferences,
      message: 'Preferences updated successfully'
    });
  } catch (error) {
    console.error('Error updating preferences:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to update preferences'
    });
  }
}

/**
 * Create default preferences for a user
 */
async function createPreferences(req, res) {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'userId is required'
      });
    }

    // Check if preferences already exist
    const existing = await get(
      'SELECT id FROM preferences WHERE user_id = ?',
      [userId]
    );

    if (existing) {
      return res.status(409).json({
        success: false,
        error: 'Preferences already exist for this user'
      });
    }

    // Create default preferences
    const result = await run(
      `INSERT INTO preferences (user_id, refresh_interval, currency, notifications_on, theme)
       VALUES (?, 15, 'INR', 1, 'light')`,
      [userId]
    );

    const newPreferences = await get(
      'SELECT * FROM preferences WHERE id = ?',
      [result.lastID]
    );

    res.status(201).json({
      success: true,
      data: newPreferences,
      message: 'Preferences created successfully'
    });
  } catch (error) {
    console.error('Error creating preferences:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to create preferences'
    });
  }
}

module.exports = {
  getPreferences,
  updatePreferences,
  createPreferences
};
