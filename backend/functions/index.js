const {onSchedule} = require("firebase-functions/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendSilentPush = onSchedule(
    {schedule: "every 1 hours"},
    async (event) => {
      const db = admin.firestore();

      console.info("🚀 Running scheduled function sendSilentPush...");

      const usersSnapshot = await db.collection("users").get();
      console.info(`📢 Found ${usersSnapshot.size} users`);

      // Use for‑of so you can await send() serially (and catch errors)
      for (const userDoc of usersSnapshot.docs) {
        const {fcmToken: token, timezone} = userDoc.data();

        console.info(`🔍 ${userDoc.id} → token? ${!!token}, tz? ${timezone}`);

        if (!token || !timezone) {
          console.warn(`⏳ Skipping ${userDoc.id}: missing token or timezone`);
          continue;
        }

        // figure out local hour
        const hours = new Date(
            new Date().toLocaleString("en-US", {timeZone: timezone}),
        ).getHours();

        if (hours !== 0) {
          console.info(`⏳ Not midnight in ${timezone}, skipping`);
          continue;
        }

        // **Build your Message object explicitly**
        const message = {
          token, // ← this must be here
          data: {dailyRefresh: "true"},
          apns: {
            headers: {
              "apns-push-type": "background",
              "apns-priority": "5",
            },
            payload: {
              aps: {"content-available": 1},
            },
          },
        };

        console.debug("FCM message:", JSON.stringify(message, null, 2));

        try {
          await admin.messaging().send(message);
          console.info(`✅ Sent silent push to ${userDoc.id}`);
        } catch (err) {
          console.error(`❌ Failed to send to ${userDoc.id}:`, err);
        }
      }

      return null;
    },
);
