// Firefox Work Profile — managed by dotfiles
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

// Translations — auto-translate all supported languages to English,
// EXCEPT Icelandic (is), which is left untranslated. Firefox has no single
// "translate everything" switch, so alwaysTranslateLanguages lists every
// supported source language; unsupported codes are ignored, and anything not
// listed still shows the one-click translate popup.
user_pref("browser.translations.mostRecentTargetLanguages", "en");
user_pref("browser.translations.neverTranslateLanguages", "is");
user_pref("browser.translations.alwaysTranslateLanguages", "ar,bg,bn,bs,ca,cs,da,de,el,es,et,fa,fi,fr,gu,he,hi,hr,hu,id,it,ja,kn,ko,lt,lv,ml,mr,ms,mt,nb,nl,nn,pa,pl,pt,ro,ru,sk,sl,sq,sr,sv,ta,te,th,tr,uk,ur,vi,zh-Hans,zh-Hant");
