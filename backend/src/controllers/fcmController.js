const { run, get, all } = require('../config/database');

/**
 * Register FCM token
 * POST /api/fcm/register
 */
async function registerToken(req, res) {
  try {
    const { token, platform } = req.body;

    if (!token || !platform) {
      return res.status(400).json({
        success: false,
        error: 'Token and platform are required',
      });
    }

    if (!['ios', 'android'].includes(platform)) {
      return res.status(400).json({
        success: false,
        error: 'Platform must be "ios" or "android"',
      });
    }

    // Get or create guest user (for now, using guest user)
    // In production, you'd get user_id from authentication
    const guestUser = await get('SELECT id FROM users WHERE email = ?', ['guest@shoprates.app']);
    if (!guestUser) {
      return res.status(500).json({
        success: false,
        error: 'Guest user not found',
      });
    }

    // Check if token already exists
    const existing = await get('SELECT id FROM fcm_tokens WHERE token = ?', [token]);

    if (existing) {
      // Update existing token
      await run(
        'UPDATE fcm_tokens SET user_id = ?, platform = ?, updated_at = CURRENT_TIMESTAMP WHERE token = ?',
        [guestUser.id, platform, token]
      );
    } else {
      // Insert new token
      await run(
        'INSERT INTO fcm_tokens (token, user_id, platform) VALUES (?, ?, ?)',
        [token, guestUser.id, platform]
      );
    }

    res.json({
      success: true,
      message: 'FCM token registered successfully',
    });
  } catch (error) {
    console.error('Error registering FCM token:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to register FCM token',
    });
  }
}

/**
 * Unregister FCM token
 * DELETE /api/fcm/unregister
 */
async function unregisterToken(req, res) {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Token is required',
      });
    }

    await run('DELETE FROM fcm_tokens WHERE token = ?', [token]);

    res.json({
      success: true,
      message: 'FCM token unregistered successfully',
    });
  } catch (error) {
    console.error('Error unregistering FCM token:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to unregister FCM token',
    });
  }
}

/**
 * Get FCM tokens for a user
 * GET /api/fcm/tokens
 */
async function getTokens(req, res) {
  try {
    // For now, using guest user
    // In production, get user_id from authentication
    const guestUser = await get('SELECT id FROM users WHERE email = ?', ['guest@shoprates.app']);
    if (!guestUser) {
      return res.status(500).json({
        success: false,
        error: 'Guest user not found',
      });
    }

    const tokens = await all(
      'SELECT token, platform, created_at, updated_at FROM fcm_tokens WHERE user_id = ?',
      [guestUser.id]
    );

    res.json({
      success: true,
      tokens: tokens,
    });
  } catch (error) {
    console.error('Error getting FCM tokens:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get FCM tokens',
    });
  }
}

/**
 * Remove invalid FCM tokens
 * Called internally when FCM reports invalid tokens
 */
async function removeInvalidTokens(invalidTokens) {
  if (!invalidTokens || invalidTokens.length === 0) {
    return;
  }

  try {
    const placeholders = invalidTokens.map(() => '?').join(',');
    await run(
      `DELETE FROM fcm_tokens WHERE token IN (${placeholders})`,
      invalidTokens
    );
    console.log(`✅ Removed ${invalidTokens.length} invalid FCM tokens`);
  } catch (error) {
    console.error('Error removing invalid FCM tokens:', error);
  }
}

/**
 * Get FCM tokens for sending notifications
 * Returns tokens for all users or specific user
 */
async function getTokensForNotification(userId = null) {
  try {
    let query = 'SELECT token FROM fcm_tokens WHERE 1=1';
    const params = [];

    if (userId) {
      query += ' AND user_id = ?';
      params.push(userId);
    }

    const tokens = await all(query, params);
    return tokens.map(row => row.token);
  } catch (error) {
    console.error('Error getting FCM tokens for notification:', error);
    return [];
  }
}

module.exports = {
  registerToken,
  unregisterToken,
  getTokens,
  removeInvalidTokens,
  getTokensForNotification,
};


