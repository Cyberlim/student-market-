const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

function initFirebase() {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      // Clean up the string in case it has surrounding quotes from .env
      let saString = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
      if ((saString.startsWith("'") && saString.endsWith("'")) || 
          (saString.startsWith('"') && saString.endsWith('"'))) {
        saString = saString.substring(1, saString.length - 1);
      }

      // Parse the JSON string
      let serviceAccount;
      if (saString.startsWith('{')) {
          serviceAccount = JSON.parse(saString);
      } else {
          // Assume base64 encoded
          const buff = Buffer.from(saString, 'base64');
          serviceAccount = JSON.parse(buff.toString('utf-8'));
      }

      // Fix private key: .env stores \\n as literal text, convert to real newlines
      if (serviceAccount.private_key) {
        serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
      }

      initializeApp({
        credential: cert(serviceAccount)
      });
      console.log('Firebase Admin SDK initialized successfully.');
    } else {
      console.warn('FIREBASE_SERVICE_ACCOUNT not provided. Push notifications will be disabled.');
    }
  } catch (error) {
    console.error('Failed to initialize Firebase Admin:', error.message);
  }
}

async function sendPushNotification(fcmToken, title, body, data = {}) {
  if (!fcmToken) return;

  const payload = {
    notification: {
      title,
      body,
    },
    data,
    token: fcmToken,
  };

  try {
    const response = await getMessaging().send(payload);
    // console.log('Successfully sent push message:', response);
  } catch (error) {
    console.error('Error sending push notification:', error.message);
  }
}

module.exports = {
  initFirebase,
  sendPushNotification,
};
