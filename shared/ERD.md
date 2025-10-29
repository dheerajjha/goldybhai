# 🗄️ Shop Rates - Entity Relationship Diagram

## Core Entities

```
 ┌───────────────────┐
 │     users         │
 │───────────────────│
 │ id (PK)           │
 │ name              │
 │ email             │
 │ created_at        │
 │ updated_at        │
 └─────────┬─────────┘
           │ 1
           │
           │ N
 ┌─────────▼──────────┐
 │    alerts          │
 │────────────────────│
 │ id (PK)            │
 │ user_id (FK→users) │
 │ commodity_id (FK→commodities) │
 │ condition ("<",">")│
 │ target_price       │
 │ active (bool)      │
 │ created_at         │
 │ triggered_at       │
 └─────────┬──────────┘
           │ N
           │
           │ 1
 ┌─────────▼──────────┐
 │   commodities      │
 │────────────────────│
 │ id (PK)            │
 │ name               │
 │ symbol             │
 │ unit (e.g., "1 kg")│
 │ type (gold/silver/coin) │
 │ created_at         │
 └─────────┬──────────┘
           │ 1
           │
           │ N
 ┌─────────▼──────────┐
 │      rates         │
 │────────────────────│
 │ id (PK)            │
 │ commodity_id (FK)  │
 │ buy_price          │
 │ sell_price         │
 │ ltp (latest price) │
 │ high               │
 │ low                │
 │ updated_at         │
 │ source             │
 └────────────────────┘

 ┌────────────────────┐
 │  preferences       │
 │────────────────────│
 │ id (PK)            │
 │ user_id (FK→users) │
 │ refresh_interval   │
 │ currency           │
 │ notifications_on   │
 │ theme              │
 └────────────────────┘

 ┌────────────────────┐
 │ notifications (opt)│
 │────────────────────│
 │ id (PK)            │
 │ alert_id (FK→alerts)│
 │ message            │
 │ sent_at            │
 │ delivered (bool)   │
 └────────────────────┘
```

## Table Details

### 🪙 commodities

Master data for all rate-tracked items.

| Column     | Type       | Example             | Notes                  |
|------------|------------|---------------------|------------------------|
| id         | INTEGER PK | 1                   | Auto-increment         |
| name       | TEXT       | "GOLD 995 WITH GST" | Display name           |
| symbol     | TEXT       | "XAU995"            | Short code             |
| unit       | TEXT       | "1 KG"              | Price per unit         |
| type       | TEXT       | "gold"              | gold/silver/coin       |
| created_at | DATETIME   | now()               | Timestamp              |

### 📈 rates

Live and historical price snapshots.

| Column       | Type                | Example              | Notes                    |
|--------------|---------------------|----------------------|--------------------------|
| id           | INTEGER PK          | 42                   | Auto-increment           |
| commodity_id | INTEGER FK          | 1                    | → commodities.id         |
| ltp          | REAL                | 122005.0             | Latest traded price      |
| buy_price    | REAL                | 122005.0             | Buy rate                 |
| sell_price   | REAL                | 122211.0             | Sell rate                |
| high         | REAL                | 124018.0             | Day high                 |
| low          | REAL                | 120225.0             | Day low                  |
| updated_at   | DATETIME            | 2025-10-29T14:20:00Z | Fetched timestamp        |
| source       | TEXT                | "arihantspot.com"    | Data source              |

### 🔔 alerts

User-defined price triggers.

| Column       | Type                | Example | Notes                         |
|--------------|---------------------|---------|-------------------------------|
| id           | INTEGER PK          | 1       | Auto-increment                |
| user_id      | INTEGER FK          | 7       | → users.id                    |
| commodity_id | INTEGER FK          | 1       | → commodities.id              |
| condition    | TEXT                | "<"     | "<" or ">"                    |
| target_price | REAL                | 3950    | Trigger price                 |
| active       | BOOLEAN             | true    | Can be disabled               |
| created_at   | DATETIME            | now()   | When alert was created        |
| triggered_at | DATETIME            | null    | When alert fired (null = not yet) |

### 👤 users

Simple user table (can expand for auth later).

| Column     | Type       | Example                 | Notes          |
|------------|------------|-------------------------|----------------|
| id         | INTEGER PK | 1                       | Auto-increment |
| name       | TEXT       | "Guest"                 | Display name   |
| email      | TEXT       | "guest@shoprates.app"   | Email address  |
| created_at | DATETIME   | now()                   | Timestamp      |
| updated_at | DATETIME   | now()                   | Last modified  |

### ⚙️ preferences

App-level user settings.

| Column            | Type          | Example | Notes                      |
|-------------------|---------------|---------|----------------------------|
| id                | INTEGER PK    | 1       | Auto-increment             |
| user_id           | INTEGER FK    | 1       | → users.id                 |
| refresh_interval  | INTEGER       | 15      | Seconds between fetches    |
| currency          | TEXT          | "INR"   | Currency display           |
| notifications_on  | BOOLEAN       | true    | Enable/disable alerts      |
| theme             | TEXT          | "dark"  | light/dark/system          |

### 📣 notifications (optional)

Logs fired alerts for history/analytics.

| Column    | Type           | Example                    | Notes          |
|-----------|----------------|----------------------------|----------------|
| id        | INTEGER PK     | 17                         | Auto-increment |
| alert_id  | INTEGER FK     | 1                          | → alerts.id    |
| message   | TEXT           | "Gold dropped below ₹3950" | Notification text |
| sent_at   | DATETIME       | now()                      | When sent      |
| delivered | BOOLEAN        | true                       | Delivery status |

## Relationships

- One user can have many alerts (1:N)
- One commodity can have many rates (1:N)
- One commodity can be in many alerts (1:N)
- One user has one preference record (1:1)
- One alert can generate many notifications (1:N)

## Indexes (for performance)

```sql
CREATE INDEX idx_rates_commodity_updated ON rates(commodity_id, updated_at DESC);
CREATE INDEX idx_alerts_user_active ON alerts(user_id, active);
CREATE INDEX idx_alerts_commodity ON alerts(commodity_id);
```
