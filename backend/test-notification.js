/**
 * Test script to send a push notification via FCM
 * Usage: node test-notification.js <fcm_token>
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require(path.join(__dirname, 'firebase-service-account.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Get FCM token from command line argument
const fcmToken = process.argv[2];

if (!fcmToken) {
  console.error('❌ Please provide FCM token as argument');
  console.log('Usage: node test-notification.js <fcm_token>');
  process.exit(1);
}

console.log('📱 Sending test notification to:', fcmToken.substring(0, 20) + '...');

// Create notification message
const message = {
  notification: {
    title: '🔔 Test Notification',
    body: 'This is a test push notification from your Gold Tracker backend!'
  },
  data: {
    type: 'test',
    timestamp: new Date().toISOString()
  },
  token: fcmToken,
  // iOS specific options - using correct APNs format
  apns: {
    headers: {
      'apns-priority': '10',
      'apns-push-type': 'alert'
    },
    payload: {
      aps: {
        alert: {
          title: '🔔 Test Notification',
          body: 'This is a test push notification from your Gold Tracker backend!'
        },
        sound: 'default',
        badge: 1,
        'content-available': 1
      }
    }
  },
  // Android specific options
  android: {
    priority: 'high',
    notification: {
      channelId: 'gold_alerts',
      priority: 'high',
      sound: 'default'
    }
  }
};

// Send the message
admin.messaging().send(message)
  .then((response) => {
    console.log('✅ Successfully sent notification:', response);
    console.log('');
    console.log('Check your iPhone for the notification!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error sending notification:', error);
    process.exit(1);
  });

