/******
 * name: user-overrides.js
 * purpose: personal customizations for arkenfox user.js
 * 
 * This file is appended to user.js when using the updater script.
 * Preferences here override the hardened defaults from arkenfox.
 ******/

/*** STARTUP & SESSION ***/
/* Enable session restore - remember tabs on restart */
user_pref("browser.startup.page", 3); // 3=resume previous session
/* Keep the blank page from arkenfox - comment out to use Firefox Home */
// user_pref("browser.startup.homepage", "about:home");

/*** HISTORY & FORMS ***/
/* Keep history and form data to stay logged into websites */
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.browsingHistoryAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.formdata", false);
user_pref("privacy.clearOnShutdown_v2.downloads", false);

/* Ensure history clearing is disabled */
user_pref("privacy.sanitize.sanitizeOnShutdown", false); // Don't clear anything on shutdown

/* Keep form history disabled for privacy */
user_pref("browser.formfill.enable", false); // Explicitly disable form memory

/*** COOKIES & SITE DATA ***/
/* Keep cookies and site data (for staying logged in) */
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
/* Alternative: Keep it true but add site exceptions in Firefox settings for sites you want to stay logged into */
/* To add exceptions: Settings > Privacy & Security > Cookies and Site Data > Manage Exceptions */
/* Add vlaris.net and other important sites as "Allow" */

/*** SITE COMPATIBILITY ***/
/* Reduce OCSP hard-fail strictness for better compatibility */
/* Uncomment if vlaris.net or other sites show SEC_ERROR_OCSP errors */
// user_pref("security.OCSP.require", false);

/* Reduce certificate pinning strictness if needed */
/* Uncomment if you see MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE on vlaris.net */
// user_pref("security.cert_pinning.enforcement_level", 1);

/* Enable WebGL if needed for specific sites */
/* Uncomment if sites need 3D graphics/maps */
// user_pref("webgl.disabled", false);

/*** MEDIA & DRM ***/
/* YouTube works fine by default, but if you need other streaming services: */
// user_pref("media.eme.enabled", true); // Enable DRM for Netflix, Disney+, etc.

/*** OPTIONAL: FINGERPRINTING RELAXATIONS ***/
/* These are currently NOT enabled in arkenfox by default, so you don't need to override them */
/* But if you later enable RFP and have issues, you can disable it selectively: */
// user_pref("privacy.resistFingerprinting", false);
user_pref("privacy.resistFingerprinting.exemptedDomains", "*.vlaris.net");

/*** SEARCH & SUGGESTIONS ***/
/* Enable search suggestions for Kagi (trusted search engine) */
user_pref("browser.search.suggest.enabled", true);
user_pref("browser.urlbar.suggest.searches", true);

/*** QUALITY OF LIFE ***/
/* Show bookmarks toolbar */
user_pref("browser.toolbars.bookmarks.visibility", "always");

/* Downloads - Based on your active profile settings */
user_pref("browser.download.useDownloadDir", true); // Don't ask where to save (override arkenfox default)
user_pref("browser.download.alwaysOpenPanel", false); // Don't auto-open download panel
user_pref("browser.download.always_ask_before_handling_new_types", true); // Ask about new file types
user_pref("browser.download.start_downloads_in_tmp_dir", true); // Use temp dir for downloads
user_pref("browser.download.manager.addToRecentDocs", false); // Don't add to recent docs

/* Firefox Home Page - Disable all content sections */
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false); // No shortcuts
user_pref("browser.newtabpage.activity-stream.showSearch", false); // No search box
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false); // No recommended stories  
user_pref("browser.newtabpage.activity-stream.feeds.weatherfeed", false); // No weather
user_pref("browser.newtabpage.activity-stream.system.showWeather", false); // No weather system
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false); // No sponsored shortcuts (already set)
user_pref("browser.newtabpage.activity-stream.showSponsored", false); // No sponsored stories (already set)

/* Disable password breach alerts */
user_pref("signon.management.page.breach-alerts.enabled", false); // No breach alerts in password manager
user_pref("services.passwordmgr.breachAlerts.enabled", false); // No breach detection service

/* Disable Firefox autofill (addresses and payment methods) */
user_pref("extensions.formautofill.addresses.enabled", false); // No address autofill
user_pref("extensions.formautofill.creditCards.enabled", false); // No payment method autofill

/* Disable daily usage ping */
user_pref("datareporting.healthreport.uploadEnabled", false); // No daily usage data to Mozilla

/* Alternative: Use completely blank new tab page instead */
user_pref("browser.newtabpage.enabled", false); // This would make new tabs completely blank

/* Disable the arkenfox update check notification */
// user_pref("app.update.suppressPrompts", true);

/*** CUSTOM FIREFOX PREFERENCES ***/
/* You can add ANY Firefox preference here! Examples: */

/* UI Customizations */
user_pref("browser.uidensity", 1); // Compact mode - smaller UI elements
user_pref("browser.tabs.loadBookmarksInTabs", true); // Open bookmarks in new tab
user_pref("browser.tabs.closeWindowWithLastTab", false); // Keep Firefox open with no tabs
user_pref("browser.tabs.crashReporting.sendReport", false); // Don't send tab crash reports
user_pref("browser.bookmarks.openInTabClosesMenu", false); // Keep bookmark menu open after clicking

/* Enable Mozilla's Native Vertical Tabs - Based on your actual prefs */
user_pref("sidebar.revamp", true); // Enable new sidebar design
user_pref("sidebar.verticalTabs", true); // Enable vertical tabs
user_pref("sidebar.position_start", true); // Sidebar on left side
user_pref("sidebar.visibility", "expand-on-hover"); // Expand sidebar on hover

/* Sidebar animations and behavior */
user_pref("sidebar.animation.expand-on-hover.duration-ms", 0); // Instant sidebar hover - no animation
user_pref("sidebar.animation.enabled", true); // Enable sidebar animations
user_pref("sidebar.animation.duration-ms", 200); // Animation duration
user_pref("sidebar.expandOnHover", true); // Expand on hover

/* Remove Sidebar Panels - Based on your actual prefs */
user_pref("browser.ml.chat.enabled", false); // Remove AI chatbot
user_pref("browser.ml.enable", false); // Kill all AI features
user_pref("browser.ml.chat.sidebar", false); // No AI chat in sidebar

/* Sidebar panel controls */
user_pref("sidebar.old-sidebar.has-used", false); // Don't show old sidebar
user_pref("sidebar.new-sidebar.has-used", true); // Use new sidebar
user_pref("sidebar.notification.badge.aichat", false); // No AI chat badge notifications

/* Disable Firefox Tools in sidebar */
user_pref("services.sync.engine.tabs", false); // No synced tabs in sidebar
user_pref("browser.tabs.firefox-view", false); // No Firefox View

/* The truth: Mozilla's vertical tabs are new and the sidebar cleanup prefs might not exist yet */
/* You might need to manually customize the sidebar by right-clicking it */

/* Toolbar Customization - Your current layout */
user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[\"_3c078156-979c-498b-8990-85f7987dd929_-browser-action\",\"search_kagi_com-browser-action\",\"addon_darkreader_org-browser-action\",\"_531906d3-e22f-4a6c-a102-8057b88a1a63_-browser-action\",\"_2662ff67-b302-4363-95f3-b050218bd72c_-browser-action\",\"_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action\"],\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"customizableui-special-spring1\",\"vertical-spacer\",\"urlbar-container\",\"ublock0_raymondhill_net-browser-action\",\"customizableui-special-spring2\",\"readeck_readeck_com-browser-action\",\"_61a05c39-ad45-4086-946f-32adb0a40a9d_-browser-action\",\"clipper_obsidian_md-browser-action\",\"harper_writewithharper_com-browser-action\",\"downloads-button\",\"unified-extensions-button\"],\"TabsToolbar\":[],\"vertical-tabs\":[\"tabbrowser-tabs\"],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"developer-button\",\"screenshot-button\",\"search_kagi_com-browser-action\",\"readeck_readeck_com-browser-action\",\"_61a05c39-ad45-4086-946f-32adb0a40a9d_-browser-action\",\"addon_darkreader_org-browser-action\",\"_531906d3-e22f-4a6c-a102-8057b88a1a63_-browser-action\",\"_2662ff67-b302-4363-95f3-b050218bd72c_-browser-action\",\"clipper_obsidian_md-browser-action\",\"ublock0_raymondhill_net-browser-action\",\"harper_writewithharper_com-browser-action\",\"_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action\",\"_3c078156-979c-498b-8990-85f7987dd929_-browser-action\"],\"dirtyAreaCache\":[\"nav-bar\",\"vertical-tabs\",\"PersonalToolbar\",\"TabsToolbar\",\"unified-extensions-area\"],\"currentVersion\":23,\"newElementCount\":5}");
user_pref("browser.uiCustomization.horizontalTabstrip", "[\"tabbrowser-tabs\",\"new-tab-button\"]"); // Backup of horizontal tab layout

/* Common items you can remove from toolbars: */
// - "home-button" (Home button)
// - "downloads-button" (Downloads button) 
// - "fxa-toolbar-menu-button" (Firefox Account button)
// - "forward-button" (Forward button)
// - "stop-reload-button" (Stop/Reload button)
// - "new-tab-button" (+ New Tab button)

// Simple approach - hide specific toolbar items:
// user_pref("browser.toolbars.bookmarks.visibility", "never"); // Hide bookmarks toolbar
// user_pref("extensions.pocket.enabled", false); // Remove Pocket button (already done by arkenfox)
// user_pref("reader.parse-on-load.enabled", false); // Remove reader mode button

// user_pref("general.autoScroll", true); // Middle-click autoscroll

/* Developer Tools */
user_pref("devtools.theme", "dark"); // Dark theme for dev tools
user_pref("devtools.chrome.enabled", true); // Enable browser chrome debugging
user_pref("devtools.debugger.remote-enabled", false); // Disable remote debugging for security

/* Media/Video */
user_pref("media.videocontrols.picture-in-picture.video-toggle.enabled", true); // PiP button on videos
user_pref("media.hardwaremediakeys.enabled", true); // Keyboard media keys work with YouTube etc.

/* Scrolling & Animation */
// user_pref("general.smoothScroll", true); // Smoother scrolling animation
// user_pref("general.autoScroll", true); // Middle-click autoscroll

/*** NOTES FOR SITE-SPECIFIC ISSUES ***/
/*
 * For vlaris.net or any other site with issues:
 * 1. Click the shield icon in the URL bar
 * 2. Turn off "Enhanced Tracking Protection" for that specific site if needed
 * 3. For canvas/fingerprinting issues, use the site exception option when prompted
 * 
 * Common error messages and fixes:
 * - SEC_ERROR_OCSP_SERVER_ERROR: Uncomment the OCSP line above
 * - MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE: Uncomment the cert_pinning line above
 * - SSL_ERROR_UNSAFE_NEGOTIATION: Uncomment in the main user.js or add:
 *   user_pref("security.ssl.require_safe_negotiation", false);
 * - Canvas/WebGL issues: Add site exceptions via the shield icon
 */

/*** BETTERFOX-INSPIRED ADDITIONS ***/
/* These are useful settings from Betterfox that Arkenfox doesn't touch */

/** ACCESSIBILITY & PERFORMANCE **/
/* Disable accessibility features for better performance (unless you need them) */
user_pref("accessibility.force_disabled", 1); // Disable accessibility entirely for performance
// user_pref("accessibility.typeaheadfind", false); // Disable type-ahead find
// user_pref("accessibility.blockautorefresh", true); // Block auto-refresh for accessibility

/* NOTE: Only disable accessibility if you don't use screen readers or similar tools */
/* To re-enable: set accessibility.force_disabled to 0 or remove the line */

/** FASTFOX PERFORMANCE OPTIMIZATIONS **/
/* Network Performance */
user_pref("network.http.max-connections", 1800); // Increase max HTTP connections
user_pref("network.http.max-persistent-connections-per-server", 10); // More connections per server
user_pref("network.http.max-urgent-start-excessive-connections-per-host", 5); // Faster urgent requests
user_pref("network.http.pacing.requests.enabled", false); // Disable request pacing for speed
user_pref("network.dnsCacheExpiration", 3600); // DNS cache for 1 hour (default 60s)

/* Memory & Caching */
user_pref("browser.cache.memory.capacity", 204800); // Increase memory cache (200MB)
user_pref("media.memory_cache_max_size", 65536); // Media cache size (64MB)
user_pref("image.mem.decode_bytes_at_a_time", 32768); // Faster image decoding

/* Rendering Performance */
user_pref("gfx.canvas.accelerated.cache-items", 4096); // GPU canvas cache
user_pref("gfx.canvas.accelerated.cache-size", 512); // Canvas cache size
user_pref("content.notify.interval", 100000); // Page reflow interval (less frequent)
user_pref("content.notify.ontimer", true); // Timer-based reflows
user_pref("content.switch.threshold", 750000); // Content switching threshold

/* Experimental Features */
user_pref("layout.css.grid-template-masonry-value.enabled", true); // CSS Masonry
user_pref("dom.enable_web_task_scheduling", true); // Web task scheduling API

/* JavaScript Performance */
user_pref("javascript.options.parallel_parsing", true); // Parallel JS parsing
user_pref("javascript.options.baselinejit.threshold", 10); // JIT threshold (default 100)

/** UI ANNOYANCES (from Peskyfox) **/
/* Disable Mozilla AI features [FF130+] */
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.sidebar", false);
user_pref("browser.ml.enable", false);

/* Remove fullscreen transition delay */
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");

/* Disable cookie banner handling (Firefox's auto-reject) */
user_pref("cookiebanners.service.mode", 0);
user_pref("cookiebanners.service.mode.privateBrowsing", 0);

/* Disable Firefox View and tab pickup */
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.tabs.firefox-view-newIcon", false);
user_pref("browser.tabs.firefox-view-next", false);
user_pref("browser.firefox-view.feature-tour", "{\"screen\":\"\",\"complete\":true}");

/* Disable default browser nag */
user_pref("browser.shell.checkDefaultBrowser", false);

/* Remove "More from Mozilla" in Settings */
user_pref("browser.preferences.moreFromMozilla", false);

/* Disable Mozilla VPN promotion */
user_pref("browser.vpn_promo.enabled", false);

/** PERFORMANCE TWEAKS **/
/* Increase session save interval from 15s to 60s (less disk writes) */
user_pref("browser.sessionstore.interval", 60000);

/* Disable automatic session restore after crash */
user_pref("browser.sessionstore.resume_from_crash", false);

/* Content Blocking - Based on your active profile */
user_pref("browser.contentblocking.category", "strict"); // Use strict content blocking

/* Experimental Features Access */
user_pref("browser.preferences.experimental.hidden", true); // Show experimental preferences

/** HTTPS-ONLY MODE **/
/* Force HTTPS on all sites - based on your active profile settings */
user_pref("dom.security.https_only_mode", true); // Force HTTPS (already active in your profile)
user_pref("dom.security.https_only_mode_send_http_background_request", false); // No HTTP fallback

/** OPTIONAL: DNS-OVER-HTTPS **/
/* Enable DoH with Cloudflare (or change provider) */
user_pref("network.trr.mode", 2); // 0=off, 2=DoH first, 3=DoH only, 5=DoH disabled
user_pref("network.trr.uri", "https://mozilla.cloudflare-dns.com/dns-query");

/** OPTIONAL: AGGRESSIVE SECURITY **/
/* Disable JavaScript JIT optimizations (more secure, less performant) */
// user_pref("javascript.options.ion", false);
// user_pref("javascript.options.baselinejit", false);
// user_pref("javascript.options.jit_trustedprincipals", true);
// user_pref("javascript.options.wasm_baselinejit", false);

/* End of user-overrides.js */