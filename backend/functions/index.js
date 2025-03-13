const {onSchedule} = require("firebase-functions/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendSilentPush = onSchedule(
    {schedule: "every 1 hours"},
    async (event) => {
      const db = admin.firestore();

      try {
        console.info("🚀 Running scheduled function sendSilentPush...");

        // Fetch all users with stored timezones
        const usersSnapshot = await db.collection("users").get();
        console.info(`📢 Found ${usersSnapshot.size} users`);

        usersSnapshot.forEach(async (userDoc) => {
          const userData = userDoc.data();
          const userToken = userData.fcmToken;
          const userTimezone = userData.timezone;

          console.info(`🔍 Checking user: ${userDoc.id},
            Token: ${userToken}, Timezone: ${userTimezone}`);

          if (!userToken || !userTimezone) {
            console.warn(`⏳ Skipping user ${userDoc.id}:
                Missing token or timezone`);
            return;
          }

          const userTime = new Date().toLocaleString("en-US",
              {timeZone: userTimezone});
          const hours = new Date(userTime).getHours();
          // const minutes = new Date(userTime).getMinutes();
          if (hours >= 0 && hours <= 23) {
            const payload = {
              data: {dailyRefresh: "true"},
              apns: {
                headers: {"apns-priority": "5"},
                payload: {aps: {"content_available": true}},
              },
            };

            try {
              console.info(`📨 Sending silent push to ${userDoc.id}
                in timezone ${userTimezone}`);
              await admin.messaging().send({
                ...payload,
                token: userToken,
              });
              console.info(`✅ Successfully sent silent push to
                ${userDoc.id}`);
            } catch (error) {
              console.error(`❌ Failed to send to
                ${userDoc.id}: ${error.message}`);
            }
          } else {
            console.info(`⏳ Skipping push for ${userDoc.id}:
                Not midnight in ${userTimezone}`);
          }
        });
      } catch (error) {
        console.error("❌ Error fetching users:", error);
        console.error(`❌ Error fetching users:
            ${error.message || error}`);
      }

      return null;
    },
);
