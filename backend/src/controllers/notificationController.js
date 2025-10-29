const { all, get, run } = require('../config/database');
const { GOLD999_COMMODITY_ID } = require('../controllers/gold999Controller');

/**
 * Get all notifications for GOLD 999 alerts
 */
async function getNotifications(req, res) {
  try {
    const { userId = 1, limit = 50, unreadOnly = false } = req.query;
    const limitInt = Math.min(parseInt(limit) || 50, 200);

    let query = `
      SELECT
        n.id,
        n.alert_id,
        n.message,
        n.sent_at,
        n.delivered,
        n.read,
        a.target_price,
        a.condition,
        a.triggered_at
      FROM notifications n
      JOIN alerts a ON n.alert_id = a.id
      WHERE a.commodity_id = ? AND a.user_id = ?
    `;

    const params = [GOLD999_COMMODITY_ID, userId];

    if (unreadOnly === 'true') {
      query += ' AND n.read = 0';
    }

    query += ' ORDER BY n.sent_at DESC LIMIT ?';
    params.push(limitInt);

    const notifications = await all(query, params);

    // Get unread count
    const unreadResult = await get(
      `SELECT COUNT(*) as count
       FROM notifications n
       JOIN alerts a ON n.alert_id = a.id
       WHERE a.commodity_id = ? AND a.user_id = ? AND n.read = 0`,
      [GOLD999_COMMODITY_ID, userId]
    );

    res.json({
      success: true,
      data: notifications,
      unread_count: unreadResult?.count || 0
    });
  } catch (error) {
    console.error('Error fetching notifications:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch notifications'
    });
  }
}

/**
 * Get unread notification count
 */
async function getUnreadCount(req, res) {
  try {
    const { userId = 1 } = req.query;

    const result = await get(
      `SELECT COUNT(*) as count
       FROM notifications n
       JOIN alerts a ON n.alert_id = a.id
       WHERE a.commodity_id = ? AND a.user_id = ? AND n.read = 0`,
      [GOLD999_COMMODITY_ID, userId]
    );

    res.json({
      success: true,
      unread_count: result?.count || 0
    });
  } catch (error) {
    console.error('Error fetching unread count:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch unread count'
    });
  }
}

/**
 * Mark notification as read
 */
async function markAsRead(req, res) {
  try {
    const { id } = req.params;
    const { userId = 1 } = req.query;

    // Verify notification belongs to user's GOLD 999 alerts
    const notification = await get(
      `SELECT n.id
       FROM notifications n
       JOIN alerts a ON n.alert_id = a.id
       WHERE n.id = ? AND a.commodity_id = ? AND a.user_id = ?`,
      [id, GOLD999_COMMODITY_ID, userId]
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        error: 'Notification not found'
      });
    }

    await run(
      `UPDATE notifications SET read = 1 WHERE id = ?`,
      [id]
    );

    res.json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (error) {
    console.error('Error marking notification as read:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to mark notification as read'
    });
  }
}

/**
 * Mark all notifications as read
 */
async function markAllAsRead(req, res) {
  try {
    const { userId = 1 } = req.query;

    await run(
      `UPDATE notifications
       SET read = 1
       WHERE alert_id IN (
         SELECT id FROM alerts
         WHERE commodity_id = ? AND user_id = ?
       ) AND read = 0`,
      [GOLD999_COMMODITY_ID, userId]
    );

    res.json({
      success: true,
      message: 'All notifications marked as read'
    });
  } catch (error) {
    console.error('Error marking all notifications as read:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to mark all notifications as read'
    });
  }
}

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead
};


