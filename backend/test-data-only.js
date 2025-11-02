/**
 * Test script to send a DATA-ONLY notification (no APNs required for testing)
 * This will test if FCM token and Firebase connection work
 * Usage: node test-data-only.js <fcm_token>
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
  console.log('Usage: node test-data-only.js <fcm_token>');
  process.exit(1);
}

console.log('📱 Sending data-only message to:', fcmToken.substring(0, 20) + '...');
console.log('ℹ️  Data-only messages bypass APNs and test FCM connectivity');

// Create data-only message (no notification payload)
const message = {
  data: {
    type: 'test',
    title: 'Test Notification',
    body: 'This is a test data message',
    timestamp: new Date().toISOString()
  },
  token: fcmToken,
  // iOS specific - content-available wakes the app
  apns: {
    headers: {
      'apns-priority': '5',
      'apns-push-type': 'background'
    },
    payload: {
      aps: {
        'content-available': 1
      }
    }
  }
};

// Send the message
admin.messaging().send(message)
  .then((response) => {
    console.log('✅ Successfully sent data message:', response);
    console.log('');
    console.log('If this works, FCM connection is fine.');
    console.log('The APNs auth error is specific to notification payloads.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error sending data message:', error);
    console.log('');
    console.log('If this also fails, there may be an issue with:');
    console.log('  1. Firebase service account credentials');
    console.log('  2. FCM token validity');
    console.log('  3. Project configuration');
    process.exit(1);
  });

