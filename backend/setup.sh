#!/bin/bash

echo "🚀 Setting up Shop Rates Backend..."
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""
echo "🗄️  Setting up database..."

# Run migrations
echo "   Running migrations..."
npm run migrate

if [ $? -ne 0 ]; then
    echo "❌ Failed to run migrations"
    exit 1
fi

# Seed data
echo "   Seeding initial data..."
npm run seed

if [ $? -ne 0 ]; then
    echo "❌ Failed to seed data"
    exit 1
fi

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "To start the server, run:"
echo "   npm run dev"
echo ""
echo "The server will run on http://localhost:3000"
echo ""
