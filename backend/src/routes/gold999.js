const express = require('express');
const router = express.Router();
const {
  getCurrentLTP,
  getChartData,
  getLastHourData,
  getLatestRate,
  GOLD999_COMMODITY_ID
} = require('../controllers/gold999Controller');
const { getAllAlerts, createAlert, updateAlert, deleteAlert } = require('../controllers/alertController');
const {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead
} = require('../controllers/notificationController');

// GET /api/gold999/current - Get current LTP (ultra-lightweight)
router.get('/current', getCurrentLTP);

// GET /api/gold999/chart - Get chart data with aggregation
router.get('/chart', getChartData);

// GET /api/gold999/last-hour - Get last 1 hour data with 1-minute intervals
router.get('/last-hour', getLastHourData);

// GET /api/gold999/latest - Get latest full rate details
router.get('/latest', getLatestRate);

// GET /api/gold999/alerts - Get alerts for GOLD 999 only
router.get('/alerts', async (req, res) => {
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
      WHERE a.user_id = ? AND a.commodity_id = ?
      ORDER BY a.created_at DESC
    `;
    
    const { all } = require('../config/database');
    const alerts = await all(query, [userId, GOLD999_COMMODITY_ID]);
    
    res.json({
      success: true,
      data: alerts
    });
  } catch (error) {
    console.error('Error fetching GOLD 999 alerts:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch alerts'
    });
  }
});

// POST /api/gold999/alerts - Create alert for GOLD 999
router.post('/alerts', (req, res, next) => {
  // Force commodity_id to GOLD 999
  req.body.commodityId = GOLD999_COMMODITY_ID;
  createAlert(req, res);
});

// PUT /api/gold999/alerts/:id - Update alert
router.put('/alerts/:id', updateAlert);

// DELETE /api/gold999/alerts/:id - Delete alert
router.delete('/alerts/:id', deleteAlert);

// GET /api/gold999/notifications - Get notifications for GOLD 999 alerts
router.get('/notifications', getNotifications);

// GET /api/gold999/notifications/unread-count - Get unread count
router.get('/notifications/unread-count', getUnreadCount);

// PUT /api/gold999/notifications/:id/read - Mark notification as read
router.put('/notifications/:id/read', markAsRead);

// PUT /api/gold999/notifications/read-all - Mark all notifications as read
router.put('/notifications/read-all', markAllAsRead);

module.exports = router;
