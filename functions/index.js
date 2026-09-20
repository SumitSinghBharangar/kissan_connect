/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendPushOnNotification = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const recipientId = data.recipientId;

    // 1. Fetch recipient's saved FCM token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
    const fcmToken = userDoc.data() ? userDoc.data().fcmToken : null;

    if (!fcmToken) return null;

    // 2. Prepare payload
    const payload = {
      token: fcmToken,
      notification: {
        title: data.title || "Kissan Connect",
        body: data.body || "",
      },
      data: {
        route: data.type === "bookingRequest" || data.type === "bookingAccepted" 
               ? "bookings" 
               : "notifications",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "kissan_connect_channel",
          sound: "default",
        },
      },
    };

    // 3. Send message through Google Play Services
    return admin.messaging().send(payload);
  });
