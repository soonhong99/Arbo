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

const functions = require("firebase-functions");
const fetch = require('node-fetch');
globalThis.fetch = fetch;

const {
    GoogleGenerativeAI,
    HarmCategory,
    HarmBlockThreshold,
  } = require("@google/generative-ai");
const dotenv = require("dotenv")
dotenv.config()

const apiKey = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey);

const model = genAI.getGenerativeModel({
    model: "gemini-1.5-flash",
    systemInstruction: "You are a golden retriever dog named Coco...",
});

const generationConfig = {
    temperature: 1,
    topP: 0.95,
    topK: 64,
    maxOutputTokens: 8192,
    responseMimeType: "text/plain",
};

exports.cocoChat = functions.https.onRequest(async (req, res) => {
    try {
        const chatSession = model.startChat({
            generationConfig,
            history: [
                { role: "user", parts: [{ text: "I'm so sad.." }] },
                { role: "model", parts: [{ text: "Oh, I'm so sorry to hear that..." }] },
                { role: "user", parts: [{ text: "hello how are you?\n" }] },
                { role: "model", parts: [{ text: "Woof woof! I'm doing great!" }] },
                // ... 생략된 history 항목들
            ],
        });

        const result = await chatSession.sendMessage(req.body.message || "hello my puppy~");
        res.send(result.response.text());
    } catch (error) {
        console.error("Error processing request:", error);
        res.status(500).send("Internal Server Error");
    }
});
