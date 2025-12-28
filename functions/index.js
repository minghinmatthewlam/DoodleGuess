const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Cloud Function: Triggered when a new drawing is created.
 * Sends a push notification to the recipient.
 */
exports.onNewDrawing = functions.firestore
  .document('drawings/{drawingId}')
  .onCreate(async (snap, context) => {
    const drawing = snap.data();
    const recipientId = drawing.toUserId;
    const senderId = drawing.fromUserId;

    // Get recipient's device token
    const recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();
    if (!recipientDoc.exists) {
      console.log('Recipient user not found:', recipientId);
      return null;
    }

    const deviceToken = recipientDoc.data().deviceToken;
    if (!deviceToken) {
      console.log('No device token for recipient:', recipientId);
      return null;
    }

    // Get sender's name for notification
    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data().name : 'Your partner';

    // Build the notification message
    const message = {
      token: deviceToken,
      notification: {
        title: 'New Drawing!',
        body: `${senderName} sent you a drawing`
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'content-available': 1
          }
        }
      },
      data: {
        drawingId: context.params.drawingId,
        type: 'new_drawing'
      }
    };

    try {
      await admin.messaging().send(message);
      console.log('Push notification sent to:', recipientId);
    } catch (error) {
      console.error('Error sending push notification:', error);
    }

    return null;
  });
