#!/bin/bash

# Production Backend Endpoint Test Script
# Tests all API endpoints for https://api-goldy.sexy.dog

BASE_URL="https://api-goldy.sexy.dog"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "=========================================="
echo "Production Endpoint Test Report"
echo "Timestamp: $TIMESTAMP"
echo "Base URL: $BASE_URL"
echo "=========================================="
echo ""

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4

    echo "Testing: $description"
    echo "Endpoint: $method $endpoint"

    if [ -z "$data" ]; then
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\nTIME:%{time_total}s" \
            -X "$method" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            "$BASE_URL$endpoint" 2>&1)
    else
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\nTIME:%{time_total}s" \
            -X "$method" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint" 2>&1)
    fi

    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d':' -f2)
    time_taken=$(echo "$response" | grep "TIME:" | cut -d':' -f2)
    body=$(echo "$response" | sed '/HTTP_STATUS:/,$d')

    echo "Status: $http_status | Time: $time_taken"
    echo "Response: $(echo $body | head -c 100)"
    echo "---"
    echo ""
}

echo "=== 1. HEALTH CHECK ==="
test_endpoint "GET" "/health" "Health Check"
echo ""

echo "=== 2. COMMODITIES API ==="
test_endpoint "GET" "/api/commodities" "Get All Commodities"
test_endpoint "GET" "/api/commodities/17" "Get Commodity by ID (GOLD999)"
test_endpoint "GET" "/api/commodities/type/gold" "Get Gold Commodities"
echo ""

echo "=== 3. RATES API ==="
test_endpoint "GET" "/api/rates/latest" "Get Latest Rates"
test_endpoint "GET" "/api/rates/17" "Get Latest Rate for GOLD999"
test_endpoint "GET" "/api/rates/17/history?page=1&limit=10" "Get Rate History"
echo ""

echo "=== 4. GOLD999 API ==="
test_endpoint "GET" "/api/gold999/current" "Get Current LTP"
test_endpoint "GET" "/api/gold999/latest" "Get Latest Full Details"
test_endpoint "GET" "/api/gold999/last-hour" "Get Last Hour Data"
test_endpoint "GET" "/api/gold999/chart?period=1h" "Get Chart Data (1h)"
test_endpoint "GET" "/api/gold999/chart?period=24h" "Get Chart Data (24h)"
echo ""

echo "=== 5. ALERTS API (Requires User ID) ==="
test_endpoint "GET" "/api/alerts?userId=test-user" "Get User Alerts"
test_endpoint "GET" "/api/alerts/active?userId=test-user" "Get Active Alerts"
test_endpoint "GET" "/api/gold999/alerts?userId=test-user" "Get GOLD999 Alerts"
echo ""

echo "=== 6. PREFERENCES API ==="
test_endpoint "GET" "/api/preferences?userId=test-user" "Get User Preferences"
echo ""

echo "=== 7. FCM API ==="
test_endpoint "GET" "/api/fcm/tokens" "Get FCM Tokens (Debug)"
echo ""

echo "=== 8. NOTIFICATIONS API ==="
test_endpoint "GET" "/api/gold999/notifications?userId=test-user" "Get Notifications"
test_endpoint "GET" "/api/gold999/notifications/unread-count?userId=test-user" "Get Unread Count"
echo ""

echo "=========================================="
echo "Test Complete"
echo "=========================================="
