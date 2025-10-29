const express = require('express');
const router = express.Router();
const {
  getAllCommodities,
  getCommodityById,
  getCommoditiesByType
} = require('../controllers/commodityController');

// GET /api/commodities - Get all commodities
router.get('/', getAllCommodities);

// GET /api/commodities/:id - Get commodity by ID
router.get('/:id', getCommodityById);

// GET /api/commodities/type/:type - Get commodities by type (gold/silver/coin)
router.get('/type/:type', getCommoditiesByType);

module.exports = router;
