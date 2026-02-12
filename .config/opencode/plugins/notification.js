import { homedir } from "os";
import { join } from "path";

const ALERT_SOUND = join(
  homedir(),
  ".config/opencode/sounds/halo_shield_recharge_phone_3a.aiff",
);

export const NotificationPlugin = async ({ $, client }) => {
  const normalizeAppName = (name) =>
    (name ?? "")
      .toLowerCase()
      .replace(/\.app$/i, "")
      .replace(/[^a-z0-9]+/g, "");

  const getTerminalAliases = (terminalProgram) => {
    const aliases = {
      appleterminal: ["appleterminal", "terminal"],
      itermapp: ["itermapp", "iterm2", "iterm"],
      ghostty: ["ghostty"],
      wezterm: ["wezterm"],
      alacritty: ["alacritty"],
      kitty: ["kitty"],
      warp: ["warp", "warpterminal"],
      warpterminal: ["warp", "warpterminal"],
      vscode: ["vscode", "code", "visualstudiocode"],
    };

    return aliases[terminalProgram] ?? [terminalProgram];
  };

  const isCurrentTerminalFrontmost = async () => {
    const terminalProgram = normalizeAppName(process.env.TERM_PROGRAM);
    if (!terminalProgram) {
      return false;
    }

    try {
      const frontmostApp = normalizeAppName(
        (
          await $`osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true'`
        ).stdout.trim(),
      );

      const aliases = getTerminalAliases(terminalProgram);
      return aliases.includes(frontmostApp);
    } catch {
      return false;
    }
  };

  // Notify only when this CLI isn't the focused tmux pane/window
  const shouldNotifyByFocus = async () => {
    const tmuxPane = process.env.TMUX_PANE;

    // Outside tmux, skip alerts only when the current terminal app is frontmost
    if (!tmuxPane) {
      return !(await isCurrentTerminalFrontmost());
    }

    try {
      const paneActive = (
        await $`tmux display-message -p -t ${tmuxPane} "#{pane_active}"`
      )
        .stdout
        .trim();

      const windowActive = (
        await $`tmux display-message -p -t ${tmuxPane} "#{window_active}"`
      )
        .stdout
        .trim();

      // Skip alerts when the pane is currently focused
      return !(paneActive === "1" && windowActive === "1");
    } catch {
      // If focus detection fails, keep notifications enabled
      return true;
    }
  };

  // Check if a session is a main (non-subagent) session
  const isMainSession = async (sessionID) => {
    try {
      const result = await client.session.get({ path: { id: sessionID } });
      const session = result.data ?? result;
      return !session.parentID;
    } catch {
      // If we can't fetch the session, assume it's main to avoid missing notifications
      return true;
    }
  };

  return {
    event: async ({ event }) => {
      // Only notify for main session events, not background subagents
      if (event.type === "session.idle") {
        const sessionID = event.properties.sessionID;
        if ((await isMainSession(sessionID)) && (await shouldNotifyByFocus())) {
          await $`afplay ${ALERT_SOUND}`;
        }
      }

      // Permission prompt created
      if (event.type === "permission.asked") {
        if (await shouldNotifyByFocus()) {
          await $`afplay ${ALERT_SOUND}`;
        }
      }
    },
  };
};
