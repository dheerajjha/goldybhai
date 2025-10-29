const { all, get } = require('../config/database');

/**
 * Get all commodities
 */
async function getAllCommodities(req, res) {
  try {
    const commodities = await all(
      'SELECT * FROM commodities ORDER BY type, name'
    );
    res.json({
      success: true,
      data: commodities
    });
  } catch (error) {
    console.error('Error fetching commodities:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch commodities'
    });
  }
}

/**
 * Get commodity by ID
 */
async function getCommodityById(req, res) {
  try {
    const { id } = req.params;
    const commodity = await get(
      'SELECT * FROM commodities WHERE id = ?',
      [id]
    );

    if (!commodity) {
      return res.status(404).json({
        success: false,
        error: 'Commodity not found'
      });
    }

    res.json({
      success: true,
      data: commodity
    });
  } catch (error) {
    console.error('Error fetching commodity:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch commodity'
    });
  }
}

/**
 * Get commodities by type (gold, silver, coin)
 */
async function getCommoditiesByType(req, res) {
  try {
    const { type } = req.params;

    if (!['gold', 'silver', 'coin'].includes(type)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid commodity type. Must be: gold, silver, or coin'
      });
    }

    const commodities = await all(
      'SELECT * FROM commodities WHERE type = ? ORDER BY name',
      [type]
    );

    res.json({
      success: true,
      data: commodities
    });
  } catch (error) {
    console.error('Error fetching commodities by type:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch commodities'
    });
  }
}

module.exports = {
  getAllCommodities,
  getCommodityById,
  getCommoditiesByType
};
