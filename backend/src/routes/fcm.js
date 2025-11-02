const express = require('express');
const router = express.Router();
const {
  registerToken,
  unregisterToken,
  getTokens,
} = require('../controllers/fcmController');

// Register FCM token
router.post('/register', registerToken);

// Unregister FCM token
router.delete('/unregister', unregisterToken);

// Get FCM tokens (for debugging)
router.get('/tokens', getTokens);

module.exports = router;


