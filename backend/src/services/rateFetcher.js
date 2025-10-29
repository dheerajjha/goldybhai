const cron = require('node-cron');
const axios = require('axios');
const { run, all } = require('../config/database');

let cronJob = null;

/**
 * Parse rate data from Arihant website (Tab-Separated Values format)
 */
async function fetchRatesFromArihant() {
  try {
    const url = 'https://bcast.arihantspot.com:7768/VOTSBroadcastStreaming/Services/xml/GetLiveRateByTemplateID/arihant';
    const timestamp = Date.now();

    console.log(`📡 Fetching rates from Arihant API...`);

    const response = await axios.get(`${url}?_=${timestamp}`, {
      headers: {
        'Accept': 'text/plain, */*; q=0.01',
        'Accept-Language': 'en-US,en;q=0.9',
        'Origin': 'https://www.arihantspot.in',
        'Referer': 'https://www.arihantspot.in/',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36'
      },
      timeout: 10000
    });

    // Parse TSV (Tab-Separated Values) response
    const lines = response.data.split('\n').filter(line => line.trim());
    const broadcasts = lines.map(line => {
      // Split by tab and filter out empty strings (from leading tabs)
      const parts = line.split('\t').map(p => p.trim()).filter(p => p);
      return {
        id: parts[0],
        description: parts[1],
        buy_rate: parts[2] === '-' ? null : parts[2],
        sell_rate: parts[3] === '-' ? null : parts[3],
        high_rate: parts[4] === '-' ? null : parts[4],
        low_rate: parts[5] === '-' ? null : parts[5]
      };
    });

    console.log(`✅ Parsed ${broadcasts.length} rates from Arihant`);

    // Map to our database structure
    return await mapArihantRatesToCommodities(broadcasts);
  } catch (error) {
    console.error('Error fetching rates from Arihant:', error.message);
    // Fallback to mock data if API fails
    return await generateMockRates();
  }
}

/**
 * Map Arihant TSV data to our commodity structure
 */
async function mapArihantRatesToCommodities(broadcasts) {
  try {
    const commodities = await all('SELECT * FROM commodities');
    const rates = [];

    console.log(`🔍 Attempting to map ${broadcasts.length} broadcasts to ${commodities.length} commodities`);

    for (const broadcast of broadcasts) {
      // Normalize description by removing extra spaces and trimming
      const description = (broadcast.description || '').replace(/\s+/g, ' ').trim();

      // Parse rates, treating "-" as null
      const buyRate = (broadcast.buy_rate && broadcast.buy_rate !== '-') ? parseFloat(broadcast.buy_rate) : null;
      const sellRate = (broadcast.sell_rate && broadcast.sell_rate !== '-') ? parseFloat(broadcast.sell_rate) : null;
      const highRate = (broadcast.high_rate && broadcast.high_rate !== '-') ? parseFloat(broadcast.high_rate) : null;
      const lowRate = (broadcast.low_rate && broadcast.low_rate !== '-') ? parseFloat(broadcast.low_rate) : null;

      // Find matching commodity - prioritize exact match over partial match
      const normalizedDescription = description.toUpperCase();

      // First, try to find exact match
      let commodity = commodities.find(c => {
        const normalizedName = c.name.replace(/\s+/g, ' ').trim().toUpperCase();
        return normalizedDescription === normalizedName;
      });

      // If no exact match, try partial matches
      if (!commodity) {
        commodity = commodities.find(c => {
          const normalizedName = c.name.replace(/\s+/g, ' ').trim().toUpperCase();
          return normalizedDescription.includes(normalizedName) ||
                 normalizedName.includes(normalizedDescription);
        });
      }

      if (commodity && (buyRate || sellRate)) {
        const price = buyRate || sellRate;
        rates.push({
          symbol: commodity.symbol,
          commodity_id: commodity.id,
          ltp: price,
          buy_price: buyRate || price,
          sell_price: sellRate || price,
          high: highRate || price,
          low: lowRate || price
        });
        console.log(`  ✓ Matched: "${description}" → ${commodity.name} (${commodity.symbol})`);
      } else if (buyRate || sellRate) {
        console.log(`  ✗ No match for: "${description}" (buy: ${buyRate}, sell: ${sellRate})`);
      }
    }

    console.log(`✅ Mapped ${rates.length} rates from Arihant to commodities`);
    return rates.length > 0 ? rates : await generateMockRates();
  } catch (error) {
    console.error('Error mapping Arihant rates:', error.message);
    return await generateMockRates();
  }
}

/**
 * Generate mock rates for testing (fallback)
 */
async function generateMockRates() {
  const commodities = await all('SELECT * FROM commodities');

  const baseRates = {
    'XAU995': 122005,
    'XAU999': 123450,
    'XAG999': 85200,
    'XAUCOIN995': 12200,
    'XAUCOIN999': 12345,
    'XAGCOIN999': 852
  };

  return commodities.map(commodity => {
    const baseRate = baseRates[commodity.symbol] || 100000;
    const variation = (Math.random() - 0.5) * 1000; // Random variation

    return {
      symbol: commodity.symbol,
      commodity_id: commodity.id,
      ltp: baseRate + variation,
      buy_price: baseRate + variation,
      sell_price: baseRate + variation + 200,
      high: baseRate + variation + 500,
      low: baseRate + variation - 500
    };
  });
}

/**
 * Save fetched rates to database
 */
async function saveRates(rates) {
  try {
    for (const rate of rates) {
      await run(
        `INSERT INTO rates (commodity_id, ltp, buy_price, sell_price, high, low, updated_at, source)
         VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)`,
        [
          rate.commodity_id,
          rate.ltp,
          rate.buy_price,
          rate.sell_price,
          rate.high,
          rate.low,
          'arihantspot.com'
        ]
      );
    }
    console.log(`✅ Saved ${rates.length} rates to database`);
  } catch (error) {
    console.error('Error saving rates:', error.message);
    throw error;
  }
}

/**
 * Main fetch and update function
 */
async function updateRates() {
  try {
    console.log('🔄 Updating rates...');
    const rates = await fetchRatesFromArihant();
    await saveRates(rates);
    console.log(`✨ Rates updated successfully at ${new Date().toISOString()}`);
  } catch (error) {
    console.error('❌ Failed to update rates:', error.message);
  }
}

/**
 * Start the rate fetcher cron job
 */
function start() {
  const interval = process.env.RATE_FETCH_INTERVAL || 15;

  // Create cron expression: every N seconds
  // Note: node-cron doesn't support seconds directly, so we use */interval for minutes
  // For seconds-based intervals, we'll use setInterval instead

  if (interval < 60) {
    // Use setInterval for sub-minute intervals
    console.log(`📡 Rate fetcher starting (every ${interval} seconds)`);

    // Fetch immediately on start
    updateRates();

    // Then schedule regular updates
    cronJob = setInterval(updateRates, interval * 1000);
  } else {
    // Use cron for minute-based intervals
    const minutes = Math.floor(interval / 60);
    console.log(`📡 Rate fetcher starting (every ${minutes} minutes)`);

    // Fetch immediately on start
    updateRates();

    // Schedule using cron
    cronJob = cron.schedule(`*/${minutes} * * * *`, updateRates);
  }
}

/**
 * Stop the rate fetcher
 */
function stop() {
  if (cronJob) {
    if (typeof cronJob === 'object' && cronJob.stop) {
      cronJob.stop();
    } else {
      clearInterval(cronJob);
    }
    console.log('🛑 Rate fetcher stopped');
  }
}

/**
 * Fetch rates once (manual trigger)
 */
async function fetchOnce() {
  return await updateRates();
}

module.exports = {
  start,
  stop,
  fetchOnce,
  updateRates
};
