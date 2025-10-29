const express = require('express');
const router = express.Router();
const {
  getLatestRates,
  getRateHistory,
  getLatestRateByCommodity
} = require('../controllers/rateController');

// GET /api/rates/latest - Get latest rates for all commodities
router.get('/latest', getLatestRates);

// GET /api/rates/:commodityId - Get latest rate for a specific commodity
router.get('/:commodityId', getLatestRateByCommodity);

// GET /api/rates/:commodityId/history - Get rate history for a commodity
router.get('/:commodityId/history', getRateHistory);

module.exports = router;
