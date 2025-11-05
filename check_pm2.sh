#!/bin/bash

# PM2 Health Check Script
# Run this script when SSH access is available

echo "=========================================="
echo "PM2 Backend Health Check"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

echo "=== PM2 Process List ==="
pm2 list
echo ""

echo "=== Backend Process Details ==="
pm2 info shoprates-backend || pm2 info backend || pm2 info 0
echo ""

echo "=== Recent Logs (Last 50 lines) ==="
pm2 logs --lines 50 --nostream
echo ""

echo "=== System Resources ==="
echo "Memory:"
free -h
echo ""
echo "Disk:"
df -h
echo ""
echo "Backend Port Status:"
netstat -tlnp | grep 3000 || ss -tlnp | grep 3000
echo ""

echo "=== Environment Check ==="
echo "Node Version: $(node --version)"
echo "PM2 Version: $(pm2 --version)"
echo "Working Directory: $(pwd)"
echo ""

echo "=== Backend Package Info ==="
if [ -f package.json ]; then
    echo "Backend Version: $(grep '"version"' package.json | head -1)"
fi
echo ""

echo "=== Database Status ==="
if [ -f data/shoprates.db ]; then
    echo "Database exists: data/shoprates.db"
    ls -lh data/shoprates.db
else
    echo "⚠️  Database file not found"
fi
echo ""

echo "=== Recent Error Logs ==="
pm2 logs --err --lines 20 --nostream
echo ""

echo "=========================================="
echo "Health Check Complete"
echo "=========================================="
