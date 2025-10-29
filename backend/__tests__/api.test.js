const request = require('supertest');
const express = require('express');
const { initDatabase, closeDatabase, run } = require('../src/config/database');
const migrate = require('../src/database/migrate');
const seed = require('../src/database/seed');

// Import routes
const commoditiesRouter = require('../src/routes/commodities');
const ratesRouter = require('../src/routes/rates');
const alertsRouter = require('../src/routes/alerts');
const preferencesRouter = require('../src/routes/preferences');

let app;

beforeAll(async () => {
  // Use in-memory database for testing
  process.env.DB_PATH = ':memory:';

  // Initialize app
  app = express();
  app.use(express.json());
  app.use('/api/commodities', commoditiesRouter);
  app.use('/api/rates', ratesRouter);
  app.use('/api/alerts', alertsRouter);
  app.use('/api/preferences', preferencesRouter);

  // Initialize database
  await initDatabase(':memory:');
  await migrate();
  await seed();
});

afterAll(async () => {
  await closeDatabase();
});

describe('Commodities API', () => {
  test('GET /api/commodities - should return all commodities', async () => {
    const response = await request(app).get('/api/commodities');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
    expect(response.body.data.length).toBeGreaterThan(0);
  });

  test('GET /api/commodities/:id - should return specific commodity', async () => {
    const response = await request(app).get('/api/commodities/1');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data).toHaveProperty('id', 1);
    expect(response.body.data).toHaveProperty('name');
    expect(response.body.data).toHaveProperty('symbol');
  });

  test('GET /api/commodities/type/gold - should return gold commodities', async () => {
    const response = await request(app).get('/api/commodities/type/gold');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
    response.body.data.forEach(commodity => {
      expect(commodity.type).toBe('gold');
    });
  });

  test('GET /api/commodities/:id - should return 404 for non-existent commodity', async () => {
    const response = await request(app).get('/api/commodities/9999');

    expect(response.status).toBe(404);
    expect(response.body.success).toBe(false);
  });
});

describe('Rates API', () => {
  beforeAll(async () => {
    // Insert some test rates
    await run(
      `INSERT INTO rates (commodity_id, ltp, buy_price, sell_price, high, low, updated_at, source)
       VALUES (1, 122000, 122000, 122200, 123000, 121000, CURRENT_TIMESTAMP, 'test')`
    );
  });

  test('GET /api/rates/latest - should return latest rates', async () => {
    const response = await request(app).get('/api/rates/latest');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
    expect(response.body).toHaveProperty('timestamp');
  });

  test('GET /api/rates/:commodityId - should return rate for specific commodity', async () => {
    const response = await request(app).get('/api/rates/1');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data).toHaveProperty('commodity_id', 1);
    expect(response.body.data).toHaveProperty('ltp');
  });

  test('GET /api/rates/:commodityId/history - should return rate history', async () => {
    const response = await request(app).get('/api/rates/1/history?limit=10');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data).toHaveProperty('commodity');
    expect(response.body.data).toHaveProperty('rates');
    expect(Array.isArray(response.body.data.rates)).toBe(true);
  });
});

describe('Alerts API', () => {
  let createdAlertId;

  test('POST /api/alerts - should create new alert', async () => {
    const response = await request(app)
      .post('/api/alerts')
      .send({
        userId: 1,
        commodityId: 1,
        condition: '<',
        targetPrice: 120000
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data).toHaveProperty('id');
    expect(response.body.data.target_price).toBe(120000);
    expect(response.body.data.condition).toBe('<');

    createdAlertId = response.body.data.id;
  });

  test('GET /api/alerts - should return all alerts', async () => {
    const response = await request(app).get('/api/alerts?userId=1');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
  });

  test('GET /api/alerts/active - should return active alerts', async () => {
    const response = await request(app).get('/api/alerts/active?userId=1');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
    response.body.data.forEach(alert => {
      expect(alert.active).toBe(1);
      expect(alert.triggered_at).toBe(null);
    });
  });

  test('GET /api/alerts/:id - should return specific alert', async () => {
    const response = await request(app).get(`/api/alerts/${createdAlertId}`);

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.id).toBe(createdAlertId);
  });

  test('PUT /api/alerts/:id - should update alert', async () => {
    const response = await request(app)
      .put(`/api/alerts/${createdAlertId}`)
      .send({
        targetPrice: 125000,
        active: true
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.target_price).toBe(125000);
  });

  test('DELETE /api/alerts/:id - should delete alert', async () => {
    const response = await request(app).delete(`/api/alerts/${createdAlertId}`);

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);

    // Verify deletion
    const getResponse = await request(app).get(`/api/alerts/${createdAlertId}`);
    expect(getResponse.status).toBe(404);
  });

  test('POST /api/alerts - should validate required fields', async () => {
    const response = await request(app)
      .post('/api/alerts')
      .send({
        userId: 1,
        // missing commodityId, condition, targetPrice
      });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
  });

  test('POST /api/alerts - should validate condition', async () => {
    const response = await request(app)
      .post('/api/alerts')
      .send({
        userId: 1,
        commodityId: 1,
        condition: '=',  // invalid condition
        targetPrice: 120000
      });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
  });
});

describe('Preferences API', () => {
  test('GET /api/preferences - should return user preferences', async () => {
    const response = await request(app).get('/api/preferences?userId=1');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data).toHaveProperty('refresh_interval');
    expect(response.body.data).toHaveProperty('currency');
    expect(response.body.data).toHaveProperty('theme');
  });

  test('PUT /api/preferences - should update preferences', async () => {
    const response = await request(app)
      .put('/api/preferences?userId=1')
      .send({
        refreshInterval: 30,
        theme: 'dark',
        currency: 'USD'
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.refresh_interval).toBe(30);
    expect(response.body.data.theme).toBe('dark');
    expect(response.body.data.currency).toBe('USD');
  });

  test('PUT /api/preferences - should validate theme', async () => {
    const response = await request(app)
      .put('/api/preferences?userId=1')
      .send({
        theme: 'invalid_theme'
      });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
  });
});

describe('Error Handling', () => {
  test('should return 404 for non-existent routes', async () => {
    const response = await request(app).get('/api/nonexistent');
    expect(response.status).toBe(404);
  });
});
