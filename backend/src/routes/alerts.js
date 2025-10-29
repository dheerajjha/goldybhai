const express = require('express');
const router = express.Router();
const {
  getAllAlerts,
  getAlertById,
  createAlert,
  updateAlert,
  deleteAlert,
  getActiveAlerts
} = require('../controllers/alertController');

// GET /api/alerts - Get all alerts for a user
router.get('/', getAllAlerts);

// GET /api/alerts/active - Get active alerts
router.get('/active', getActiveAlerts);

// GET /api/alerts/:id - Get alert by ID
router.get('/:id', getAlertById);

// POST /api/alerts - Create a new alert
router.post('/', createAlert);

// PUT /api/alerts/:id - Update an alert
router.put('/:id', updateAlert);

// DELETE /api/alerts/:id - Delete an alert
router.delete('/:id', deleteAlert);

module.exports = router;
