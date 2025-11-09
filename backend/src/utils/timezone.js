/**
 * Timezone Utility for IST (Indian Standard Time)
 * 
 * This module ensures all timestamps in the system are in IST.
 * IST is UTC+5:30 (5 hours 30 minutes ahead of UTC)
 */

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000; // 5 hours 30 minutes in milliseconds

/**
 * Get current time in IST
 * @returns {Date} Current date/time in IST
 */
function getCurrentIST() {
  const now = new Date();
  const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
  return new Date(utc + IST_OFFSET_MS);
}

/**
 * Convert any Date to IST
 * @param {Date} date - Date to convert
 * @returns {Date} Date in IST
 */
function toIST(date) {
  const utc = date.getTime() + (date.getTimezoneOffset() * 60000);
  return new Date(utc + IST_OFFSET_MS);
}

/**
 * Format IST date for SQLite (YYYY-MM-DD HH:MM:SS)
 * @param {Date} date - Date to format (defaults to current IST time)
 * @returns {string} Formatted date string for SQLite
 */
function formatForSQLite(date = null) {
  const istDate = date ? toIST(date) : getCurrentIST();
  
  const year = istDate.getFullYear();
  const month = String(istDate.getMonth() + 1).padStart(2, '0');
  const day = String(istDate.getDate()).padStart(2, '0');
  const hours = String(istDate.getHours()).padStart(2, '0');
  const minutes = String(istDate.getMinutes()).padStart(2, '0');
  const seconds = String(istDate.getSeconds()).padStart(2, '0');
  
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}

/**
 * Parse SQLite timestamp string to Date object (assumes IST)
 * @param {string} sqliteTimestamp - SQLite timestamp string (YYYY-MM-DD HH:MM:SS)
 * @returns {Date} Date object representing IST time
 */
function parseFromSQLite(sqliteTimestamp) {
  // SQLite format: 'YYYY-MM-DD HH:MM:SS'
  // We treat this as IST time
  const [datePart, timePart] = sqliteTimestamp.split(' ');
  const [year, month, day] = datePart.split('-').map(Number);
  const [hours, minutes, seconds] = timePart.split(':').map(Number);
  
  // Create a date object (this will be in local timezone)
  const date = new Date(year, month - 1, day, hours, minutes, seconds);
  
  // Return as-is since we're treating it as IST
  return date;
}

/**
 * Get IST timestamp for "X time ago" calculations
 * @param {number} hours - Hours to subtract
 * @returns {string} SQLite-formatted timestamp
 */
function getISTTimeAgo(hours) {
  const now = getCurrentIST();
  const timeAgo = new Date(now.getTime() - (hours * 60 * 60 * 1000));

  // Don't call formatForSQLite which would double-convert to IST
  // Instead, format directly since timeAgo is already in IST
  const year = timeAgo.getFullYear();
  const month = String(timeAgo.getMonth() + 1).padStart(2, '0');
  const day = String(timeAgo.getDate()).padStart(2, '0');
  const hoursStr = String(timeAgo.getHours()).padStart(2, '0');
  const minutes = String(timeAgo.getMinutes()).padStart(2, '0');
  const seconds = String(timeAgo.getSeconds()).padStart(2, '0');

  return `${year}-${month}-${day} ${hoursStr}:${minutes}:${seconds}`;
}

/**
 * Format IST date for API response (ISO 8601 format with IST offset)
 * @param {string} sqliteTimestamp - SQLite timestamp string
 * @returns {string} ISO 8601 formatted string with +05:30 offset
 */
function formatForAPI(sqliteTimestamp) {
  // Return as-is since it's already in IST
  // Frontend will parse this as local time (IST)
  return sqliteTimestamp;
}

module.exports = {
  getCurrentIST,
  toIST,
  formatForSQLite,
  parseFromSQLite,
  getISTTimeAgo,
  formatForAPI,
  IST_OFFSET_MS
};

