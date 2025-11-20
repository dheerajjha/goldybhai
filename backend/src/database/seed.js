require('dotenv').config();
const { initDatabase, run, get, closeDatabase } = require('../config/database');

const seedData = {
  users: [
    { name: 'Guest User', email: 'guest@shoprates.app' }
  ],

  commodities: [
    // Existing commodities with GST
    { name: 'GOLD 995 WITH GST INDIAN-BIS', symbol: 'XAU995', unit: '1 KG', type: 'gold' },
    { name: 'GOLD 999 IMP (LBMA) WITH GST', symbol: 'XAU999', unit: '1 KG', type: 'gold' },
    { name: 'GOLD 99.99 (4 NINE) IMP WITH GST', symbol: 'XAU9999GST', unit: '1 KG', type: 'gold' },
    { name: 'SILVER 999 WITH GST', symbol: 'XAG999', unit: '1 KG', type: 'silver' },

    // Reference prices
    { name: 'Gold', symbol: 'GOLDREF', unit: '1 KG', type: 'gold' },
    { name: 'GOLD COST', symbol: 'GOLDCOST', unit: '1 KG', type: 'gold' },

    // Imported gold variants - T+0 (same day delivery)
    { name: 'GOLD 995 (1kg) IMPORTED T+0', symbol: 'XAU995IMP', unit: '1 KG', type: 'gold' },
    { name: 'GOLD 999 IMPORTED (500gm) T+0', symbol: 'XAU999IMP500', unit: '500 GM', type: 'gold' },
    { name: 'GOLD 995 (500gm) T+0', symbol: 'XAU995-500', unit: '500 GM', type: 'gold' },

    // Future delivery - 30th OCT
    { name: 'GOLD 995 IMPORTED (1KG) 30th OCT', symbol: 'XAU995IMPOCT', unit: '1 KG', type: 'gold' },
    { name: 'GOLD 99.99 (4 NINE) IMPORTED (1KG) 30th OCT', symbol: 'XAU9999IMPOCT', unit: '1 KG', type: 'gold' },

    // Currency (categorized as gold for display purposes)
    { name: 'USD INR', symbol: 'USDINR', unit: 'PER USD', type: 'gold' },

    // Coins
    { name: 'GOLD COIN 995', symbol: 'XAUCOIN995', unit: '10 GM', type: 'coin' },
    { name: 'GOLD COIN 999', symbol: 'XAUCOIN999', unit: '10 GM', type: 'coin' },
    { name: 'SILVER COIN 999', symbol: 'XAGCOIN999', unit: '100 GM', type: 'coin' }
  ]
};

async function seed() {
  try {
    console.log('Starting database seeding...');
    await initDatabase();

    // Seed users
    console.log('Seeding users...');
    for (const user of seedData.users) {
      const existing = await get('SELECT id FROM users WHERE email = ?', [user.email]);
      if (!existing) {
        await run(
          'INSERT INTO users (name, email) VALUES (?, ?)',
          [user.name, user.email]
        );
        console.log(`  ✓ Created user: ${user.name}`);
      } else {
        console.log(`  ⊘ User already exists: ${user.name}`);
      }
    }

    // Seed commodities
    console.log('Seeding commodities...');
    for (const commodity of seedData.commodities) {
      const existing = await get('SELECT id FROM commodities WHERE symbol = ?', [commodity.symbol]);
      if (!existing) {
        await run(
          'INSERT INTO commodities (name, symbol, unit, type) VALUES (?, ?, ?, ?)',
          [commodity.name, commodity.symbol, commodity.unit, commodity.type]
        );
        console.log(`  ✓ Created commodity: ${commodity.name}`);
      } else {
        console.log(`  ⊘ Commodity already exists: ${commodity.name}`);
      }
    }

    // Create default preferences for guest user
    console.log('Creating default preferences...');
    const guestUser = await get('SELECT id FROM users WHERE email = ?', ['guest@shoprates.app']);
    if (guestUser) {
      const existingPref = await get('SELECT id FROM preferences WHERE user_id = ?', [guestUser.id]);
      if (!existingPref) {
        await run(
          'INSERT INTO preferences (user_id, refresh_interval, currency, notifications_on, theme) VALUES (?, ?, ?, ?, ?)',
          [guestUser.id, 15, 'INR', 1, 'light']
        );
        console.log('  ✓ Created default preferences');
      } else {
        console.log('  ⊘ Preferences already exist');
      }
    }

    console.log('✅ Seeding completed successfully!');
    await closeDatabase();
  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
    await closeDatabase();
    process.exit(1);
  }
}

// Run seeding if this file is executed directly
if (require.main === module) {
  seed();
}

module.exports = seed;
