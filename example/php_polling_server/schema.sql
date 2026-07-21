-- ═══════════════════════════════════════════════════════════════════
--  Notification Master — Polling Server Database Schema
--  Compatible with MySQL 5.7+ / MariaDB 10.3+
-- ═══════════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS notification_master
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE notification_master;

-- ---------------------------------------------------------------
--  notifications
--  Rows are delivered once (delivered_at IS NULL) then marked done.
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  title         VARCHAR(255)    NOT NULL,
  message       TEXT            NOT NULL,
  big_text      TEXT            NULL COMMENT 'Optional expanded body; overrides message on Windows/Android',
  image_url     VARCHAR(2048)   NULL COMMENT 'HTTP/HTTPS URL shown as notification image',
  channel_id    VARCHAR(100)    NULL COMMENT 'Android notification channel id (ignored on Windows)',
  target_screen VARCHAR(255)    NULL COMMENT 'App route to open on tap (e.g. /orders/42)',
  extra_data    JSON            NULL COMMENT 'Arbitrary key-value pairs forwarded to the app',
  created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deliver_after DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Do not return before this time',
  delivered_at  DATETIME        NULL     COMMENT 'Set by API when the row is returned to a poller; NULL = pending',
  PRIMARY KEY (id),
  INDEX idx_pending (delivered_at, deliver_after)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------
--  Sample rows — useful for first-run testing
-- ---------------------------------------------------------------
INSERT INTO notifications (title, message, big_text, image_url, target_screen)
VALUES
  ('سلام از سرور!',     'اولین نوتیفیکیشن تست پولینگ ویندوز.', NULL,                                                          NULL,                                   NULL),
  ('Breaking News',     'Short summary here.',                  'This is the full expanded body text that appears when the notification is expanded on supported platforms.', NULL, '/news/1'),
  ('Image Notification','Check out this photo!',                NULL,                                                          'https://picsum.photos/300/200',        '/gallery'),
  ('Order Shipped',     'Your order #1042 is on its way.',      'Expected delivery: tomorrow between 09:00 and 13:00. Track at example.com/track/1042', NULL, '/orders/1042');
