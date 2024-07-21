/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// 내가 주석 1
// const {onRequest} = require("firebase-functions/v2/https");
require("firebase-functions/v2/https");

// 내가 주석 2
// const logger = require("firebase-functions/logger");


// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.cleanupUnverifiedUsers = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  const cutoff = admin.firestore.Timestamp.fromMillis(now.toMillis() - 3600000); // 1 hour ago

  const snapshot = await admin.firestore().collection('temp_users').where('createdAt', '<', cutoff).get();

  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  const auth = admin.auth();
  for (const doc of snapshot.docs) {
    try {
      await auth.deleteUser(doc.id);
    } catch (error) {
      console.log(`Error deleting user ${doc.id}:`, error);
    }
  }

  return null;
});