<?php
// ─────────────────────────────────────────────────────────────────────────────
//  Notification Master — Polling Server Configuration
//  Edit these values to match your environment.
// ─────────────────────────────────────────────────────────────────────────────

define('DB_HOST',     'localhost');
define('DB_PORT',     3306);
define('DB_NAME',     'notification_master');
define('DB_USER',     'root');          // change to a dedicated DB user in production
define('DB_PASS',     '');             // set your password

// How many notifications to return per poll request.
define('MAX_PER_POLL', 5);

// Set to true during development to include DB errors in the JSON response.
define('DEBUG_MODE', true);
