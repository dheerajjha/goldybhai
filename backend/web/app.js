// API Configuration
const API_BASE_URL = 'http://localhost:3000/api';
const USER_ID = 1; // Default user ID

// State Management
let commodities = [];
let rates = [];
let alerts = [];
let preferences = {};
let refreshInterval = null;

// DOM Elements
const statusDot = document.getElementById('status-dot');
const statusText = document.getElementById('status-text');
const lastUpdateTime = document.getElementById('last-update-time');
const ratesContainer = document.getElementById('rates-container');
const alertsContainer = document.getElementById('alerts-container');
const commodityFilter = document.getElementById('commodity-filter');
const refreshBtn = document.getElementById('refresh-btn');
const createAlertBtn = document.getElementById('create-alert-btn');
const alertModal = document.getElementById('alert-modal');
const alertForm = document.getElementById('alert-form');
const cancelAlertBtn = document.getElementById('cancel-alert-btn');
const savePreferencesBtn = document.getElementById('save-preferences-btn');

// Tab Navigation
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tabName = btn.dataset.tab;
        switchTab(tabName);
    });
});

function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`${tabName}-tab`).classList.add('active');

    // Load data for the tab
    if (tabName === 'rates') {
        loadRates();
    } else if (tabName === 'alerts') {
        loadAlerts();
    } else if (tabName === 'preferences') {
        loadPreferences();
    }
}

// API Functions
async function apiCall(endpoint, options = {}) {
    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers,
            },
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        return data;
    } catch (error) {
        console.error('API call failed:', error);
        updateStatus(false);
        throw error;
    }
}

async function checkHealth() {
    try {
        const response = await fetch('http://localhost:3000/health');
        const data = await response.json();
        updateStatus(true);
        return data;
    } catch (error) {
        updateStatus(false);
        throw error;
    }
}

function updateStatus(connected) {
    if (connected) {
        statusDot.classList.add('connected');
        statusDot.classList.remove('disconnected');
        statusText.textContent = 'Connected';
    } else {
        statusDot.classList.add('disconnected');
        statusDot.classList.remove('connected');
        statusText.textContent = 'Disconnected';
    }
}

// Load Commodities
async function loadCommodities() {
    try {
        const data = await apiCall('/commodities');
        commodities = data.data || [];
        populateCommoditySelect();
        return commodities;
    } catch (error) {
        console.error('Failed to load commodities:', error);
        return [];
    }
}

// Load Rates
async function loadRates() {
    try {
        ratesContainer.innerHTML = '<div class="loading">Loading rates...</div>';
        const data = await apiCall('/rates/latest');
        rates = data.data || [];
        
        const filter = commodityFilter.value;
        const filteredRates = filter === 'all' 
            ? rates 
            : rates.filter(rate => rate.type === filter);
        
        displayRates(filteredRates);
        updateLastUpdateTime(data.timestamp);
        updateStatus(true);
    } catch (error) {
        ratesContainer.innerHTML = '<div class="error">Failed to load rates. Please check if the server is running.</div>';
        updateStatus(false);
    }
}

function displayRates(ratesData) {
    if (ratesData.length === 0) {
        ratesContainer.innerHTML = '<div class="error">No rates available</div>';
        return;
    }

    ratesContainer.innerHTML = ratesData.map(rate => `
        <div class="rate-card ${rate.type}">
            <div class="commodity-header">
                <div>
                    <div class="commodity-name">${rate.commodity_name}</div>
                    <div class="commodity-symbol">${rate.symbol}</div>
                </div>
                <span class="commodity-type">${rate.type}</span>
            </div>
            <div class="price-section">
                <div class="price-main">₹${formatPrice(rate.ltp)}</div>
                <div class="price-label">Last Traded Price</div>
                <div class="price-row">
                    <span>Buy Price:</span>
                    <span class="price-value">₹${formatPrice(rate.buy_price)}</span>
                </div>
                <div class="price-row">
                    <span>Sell Price:</span>
                    <span class="price-value">₹${formatPrice(rate.sell_price)}</span>
                </div>
                <div class="price-row">
                    <span>High:</span>
                    <span class="price-value price-positive">₹${formatPrice(rate.high)}</span>
                </div>
                <div class="price-row">
                    <span>Low:</span>
                    <span class="price-value price-negative">₹${formatPrice(rate.low)}</span>
                </div>
            </div>
            <div class="update-time">
                Updated: ${formatTime(rate.updated_at)}
            </div>
        </div>
    `).join('');
}

// Load Alerts
async function loadAlerts() {
    try {
        alertsContainer.innerHTML = '<div class="loading">Loading alerts...</div>';
        const data = await apiCall(`/alerts?userId=${USER_ID}`);
        alerts = data.data || [];
        displayAlerts(alerts);
    } catch (error) {
        alertsContainer.innerHTML = '<div class="error">Failed to load alerts</div>';
    }
}

function displayAlerts(alertsData) {
    if (alertsData.length === 0) {
        alertsContainer.innerHTML = '<div class="error">No alerts created yet. Create one to get notified when prices change!</div>';
        return;
    }

    alertsContainer.innerHTML = alertsData.map(alert => `
        <div class="alert-card ${alert.active ? '' : 'inactive'}">
            <div class="alert-info">
                <div class="alert-commodity">${alert.commodity_name} (${alert.symbol})</div>
                <div class="alert-condition">
                    Alert when price ${alert.condition === '<' ? 'drops below' : 'rises above'}
                </div>
                <div class="alert-target">₹${formatPrice(alert.target_price)}</div>
                <span class="alert-status ${alert.triggered_at ? 'triggered' : 'active'}">
                    ${alert.triggered_at ? '✓ Triggered' : alert.active ? 'Active' : 'Inactive'}
                </span>
                ${alert.triggered_at ? `<div style="margin-top: 5px; font-size: 0.85em; color: var(--text-secondary);">Triggered: ${formatTime(alert.triggered_at)}</div>` : ''}
            </div>
            <div class="alert-actions">
                <button class="btn btn-secondary" onclick="toggleAlert(${alert.id}, ${!alert.active})">
                    ${alert.active ? 'Disable' : 'Enable'}
                </button>
                <button class="btn btn-danger" onclick="deleteAlert(${alert.id})">Delete</button>
            </div>
        </div>
    `).join('');
}

// Load Preferences
async function loadPreferences() {
    try {
        const data = await apiCall(`/preferences?userId=${USER_ID}`);
        preferences = data.data || {};
        
        const refreshInterval = preferences.refresh_interval || 15;
        document.getElementById('refresh-interval').value = refreshInterval;
        document.getElementById('currency').value = preferences.currency || 'INR';
        document.getElementById('theme').value = preferences.theme || 'light';
        document.getElementById('notifications-on').checked = preferences.notifications_on === 1;
        
        // Setup auto refresh with loaded preferences
        setupAutoRefresh(refreshInterval);
    } catch (error) {
        console.log('Preferences not found or failed to load, using defaults:', error.message);
        // If preferences don't exist or fail to load, use defaults and setup auto refresh
        preferences = {};
        document.getElementById('refresh-interval').value = 15;
        document.getElementById('currency').value = 'INR';
        document.getElementById('theme').value = 'light';
        document.getElementById('notifications-on').checked = true;
        
        // Setup auto refresh with default interval
        setupAutoRefresh(15);
    }
}

// Create Alert
function populateCommoditySelect() {
    const select = document.getElementById('alert-commodity');
    select.innerHTML = '<option value="">Select a commodity...</option>' +
        commodities.map(c => `<option value="${c.id}">${c.name} (${c.symbol})</option>`).join('');
}

createAlertBtn.addEventListener('click', () => {
    alertModal.classList.add('active');
});

cancelAlertBtn.addEventListener('click', () => {
    alertModal.classList.remove('active');
    alertForm.reset();
});

document.querySelector('.close').addEventListener('click', () => {
    alertModal.classList.remove('active');
    alertForm.reset();
});

alertForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const commodityId = parseInt(document.getElementById('alert-commodity').value);
    const condition = document.getElementById('alert-condition').value;
    const targetPrice = parseFloat(document.getElementById('alert-price').value);

    try {
        await apiCall('/alerts', {
            method: 'POST',
            body: JSON.stringify({
                userId: USER_ID,
                commodityId,
                condition,
                targetPrice
            })
        });
        
        alertModal.classList.remove('active');
        alertForm.reset();
        loadAlerts();
    } catch (error) {
        alert('Failed to create alert. Please try again.');
    }
});

// Update Alert
async function toggleAlert(alertId, active) {
    try {
        await apiCall(`/alerts/${alertId}`, {
            method: 'PUT',
            body: JSON.stringify({ active })
        });
        loadAlerts();
    } catch (error) {
        alert('Failed to update alert');
    }
}

// Delete Alert
async function deleteAlert(alertId) {
    if (!confirm('Are you sure you want to delete this alert?')) {
        return;
    }
    
    try {
        await apiCall(`/alerts/${alertId}`, {
            method: 'DELETE'
        });
        loadAlerts();
    } catch (error) {
        alert('Failed to delete alert');
    }
}

// Save Preferences
savePreferencesBtn.addEventListener('click', async () => {
    const refreshInterval = parseInt(document.getElementById('refresh-interval').value);
    const currency = document.getElementById('currency').value;
    const theme = document.getElementById('theme').value;
    const notificationsOn = document.getElementById('notifications-on').checked;

    try {
        await apiCall(`/preferences?userId=${USER_ID}`, {
            method: 'PUT',
            body: JSON.stringify({
                refreshInterval,
                currency,
                theme,
                notificationsOn
            })
        });
        
        // Reload preferences to sync state
        await loadPreferences();
        
        alert('Preferences saved successfully!');
    } catch (error) {
        // If preferences don't exist, try to create them
        if (error.message && error.message.includes('404')) {
            try {
                await apiCall('/preferences', {
                    method: 'POST',
                    body: JSON.stringify({ userId: USER_ID })
                });
                // Then try updating again
                await apiCall(`/preferences?userId=${USER_ID}`, {
                    method: 'PUT',
                    body: JSON.stringify({
                        refreshInterval,
                        currency,
                        theme,
                        notificationsOn
                    })
                });
                await loadPreferences();
                alert('Preferences created and saved successfully!');
            } catch (createError) {
                alert('Failed to create preferences. Please try again.');
            }
        } else {
            alert('Failed to save preferences');
        }
    }
});

// Utility Functions
function formatPrice(price) {
    return new Intl.NumberFormat('en-IN', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    }).format(price);
}

function formatTime(timestamp) {
    if (!timestamp) return 'Never';
    const date = new Date(timestamp);
    return date.toLocaleString('en-IN', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function updateLastUpdateTime(timestamp) {
    if (timestamp) {
        lastUpdateTime.textContent = formatTime(timestamp);
    }
}

// Event Listeners
commodityFilter.addEventListener('change', () => {
    const filter = commodityFilter.value;
    const filteredRates = filter === 'all' 
        ? rates 
        : rates.filter(rate => rate.type === filter);
    displayRates(filteredRates);
});

refreshBtn.addEventListener('click', () => {
    loadRates();
});

// Auto Refresh
function setupAutoRefresh(intervalSeconds = 15) {
    // Clear existing interval if any
    if (refreshInterval) {
        clearInterval(refreshInterval);
        refreshInterval = null;
    }
    
    console.log(`Setting up auto-refresh every ${intervalSeconds} seconds`);
    
    refreshInterval = setInterval(() => {
        const ratesTab = document.getElementById('rates-tab');
        if (ratesTab && ratesTab.classList.contains('active')) {
            console.log('Auto-refreshing rates...');
            loadRates();
        }
    }, intervalSeconds * 1000);
    
    console.log('Auto-refresh interval set successfully');
}

// Initialize
async function init() {
    // Check health
    await checkHealth();
    
    // Load initial data
    await loadCommodities();
    await loadRates();
    await loadPreferences(); // This will setup auto refresh after loading preferences
    
    // Check health periodically
    setInterval(checkHealth, 30000); // Every 30 seconds
}

// Start the app
init();

