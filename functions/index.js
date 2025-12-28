const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyNewDrawing = onDocumentCreated("drawings/{drawingId}", async (event) => {
  const data = event.data?.data();
  if (!data) return;

  const toUserId = data.toUserId;
  const fromUserId = data.fromUserId;
  if (!toUserId || !fromUserId) return;

  const toUserSnap = await admin.firestore().doc(`users/${toUserId}`).get();
  const token = toUserSnap.get("deviceToken");
  if (!token) return;

  const fromUserSnap = await admin.firestore().doc(`users/${fromUserId}`).get();
  const senderName = fromUserSnap.exists
    ? (fromUserSnap.get("name") || "Your partner")
    : "Your partner";

  const message = {
    token,
    notification: {
      title: "New doodle",
      body: `${senderName} sent you a doodle`
    },
    data: {
      drawingId: event.params.drawingId,
      fromUserId,
      type: "new_doodle"
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          "content-available": 1
        }
      }
    }
  };

  await admin.messaging().send(message);
});
