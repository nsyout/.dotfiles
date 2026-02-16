import { homedir } from "os";
import { join } from "path";

export const NotificationPlugin = async ({ $, client }) => {
  const soundPath = join(
    homedir(),
    ".dotfiles/sounds/schlock_2_phone_3a.aiff",
  );
  let isPlaying = false;

  const playNotificationSound = async () => {
    if (isPlaying) return;
    isPlaying = true;
    try {
      await $`afplay ${soundPath}`;
    } finally {
      isPlaying = false;
    }
  };

  const isMainSession = async (sessionID) => {
    try {
      const result = await client.session.get({ path: { id: sessionID } });
      const session = result.data ?? result;
      return !session.parentID;
    } catch {
      return true;
    }
  };

  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        const sessionID = event.properties?.sessionID;
        if (!sessionID) return;
        if (await isMainSession(sessionID)) {
          await playNotificationSound();
        }
      }

      if (event.type === "permission.asked") {
        await playNotificationSound();
      }
    },
  };
};
