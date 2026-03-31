// Firefox Personal Profile — managed by dotfiles
// Applied on every startup. Firefox Sync handles passwords, bookmarks, extensions.

// Session restore — reopen previous windows and tabs
user_pref("browser.startup.page", 3);

// Privacy — enable tracking protection
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);

// Multi-Account Containers support
user_pref("privacy.userContext.enabled", true);
user_pref("privacy.userContext.ui.enabled", true);

// Don't ask to be default browser
user_pref("browser.shell.checkDefaultBrowser", false);

// Disable Firefox welcome/onboarding on fresh profile
user_pref("browser.aboutwelcome.enabled", false);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
