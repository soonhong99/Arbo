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

// 내가 쓰는 코드
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const algoliasearch = require("algoliasearch");

admin.initializeApp();


const ALGOLIA_INDEX_NAME = "posts";

// const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

const client = algoliasearch(
    functions.config().algolia.appid_dev,
    functions.config().algolia.writeapikey_dev,
    functions.config().algolia.searchapikey_dev,
);

const index = client.initIndex(ALGOLIA_INDEX_NAME);

exports.onPostCreated = functions
    .region("asia-northeast3")
    .firestore
    .document("posts/{postId}")
    .onCreate(async (snap, context) => {
      const postData = snap.data();
      postData.objectID = context.params.postId;

      await index.saveObject(postData);
    });

exports.onPostUpdated = functions
    .region("asia-northeast3")
    .firestore
    .document("posts/{postId}")
    .onUpdate(async (change, context) => {
      const postData = change.after.data();
      const prevpostData = change.before.data();
      postData.objectID = context.params.postId;

      await index.saveObject(postData);
    });

exports.onPostDeleted = functions
    .region("asia-northeast3")
    .firestore
    .document("posts/{postId}")
    .onDelete(async (snap, context) => {
      const objectID = context.params.postId;

      await index.deleteObject(objectID);
    });
