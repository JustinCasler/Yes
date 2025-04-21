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
        console.error(`❌ Error fetching users:
            ${error.message || error}`);
      }

      return null;
    },
);

exports.sendDailyStreakNotification = functions.pubsub.schedule("every 1 hours").onRun(async () => {
  const db = admin.firestore();

  try {
    console.info("⏰ Running daily streak notification job...");

    const usersSnapshot = await db.collection("users").get();
    console.info(`👥 Found ${usersSnapshot.size} users`);

    usersSnapshot.forEach(async (userDoc) => {
      const userData = userDoc.data();
      const userToken = userData.fcmToken;
      const userTimezone = userData.timezone;
      const streaks = userData.streaks;

      if (!userToken || !userTimezone || streaks === undefined) {
        console.warn(`⚠️ Skipping user ${userDoc.id}: Missing required fields`);
        return;
      }

      const userTime = new Date().toLocaleString("en-US", {
        timeZone: userTimezone,
      });
      const currentHour = new Date(userTime).getHours();

      if (currentHour === 10) {
        const nextStreak = parseInt(streaks, 10) + 1;

        const payload = {
          notification: {
            title: "Say Yes to Life Today",
            body: `Complete your challenge to reach ${nextStreak} in a row`,
          },
          token: userToken,
        };

        try {
          console.info(`📨 Sending notification to ${userDoc.id} (streak: ${streaks})`);
          await admin.messaging().send(payload);
          console.info(`✅ Notification sent to ${userDoc.id}`);
        } catch (error) {
          console.error(`❌ Error sending to ${userDoc.id}: ${error.message}`);
        }
      } else {
        console.info(`🕙 Not 10 AM yet for ${userDoc.id} (hour: ${currentHour})`);
      }
    });
  } catch (error) {
    console.error(`❌ Failed to send streak notifications: ${error.message}`);
  }

  return null;
});

