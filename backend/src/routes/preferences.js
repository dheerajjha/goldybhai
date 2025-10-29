const express = require('express');
const router = express.Router();
const {
  getPreferences,
  updatePreferences,
  createPreferences
} = require('../controllers/preferenceController');

// GET /api/preferences - Get user preferences
router.get('/', getPreferences);

// POST /api/preferences - Create preferences
router.post('/', createPreferences);

// PUT /api/preferences - Update preferences
router.put('/', updatePreferences);

module.exports = router;
