// Firefox Default Profile — throwaway browsing, no session persistence
// Applied on every startup. Tabs are not saved between sessions.

// Start with homepage, not previous session
user_pref("browser.startup.page", 1);

// Privacy — enable tracking protection
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);

// Don't ask to be default browser
user_pref("browser.shell.checkDefaultBrowser", false);
