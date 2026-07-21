# Notification Master — PHP Polling Test Server

A minimal PHP + MySQL backend to test Windows background polling.
The Windows daemon (`notification_master_poller.exe`) polls this endpoint,
parses the JSON, and fires a Toast notification — even after the Flutter app is closed.

---

## Files

| File | Purpose |
|------|---------|
| `schema.sql` | Create the database and `notifications` table |
| `config.php` | DB credentials (edit before first run) |
| `notifications.php` | The polling endpoint (`GET`) + insert endpoint (`POST`) |

---

## Setup (XAMPP / WAMP / any PHP 7.4+ server)

### 1. Create the database

```sql
-- In phpMyAdmin or MySQL CLI:
SOURCE /path/to/schema.sql;
```

Or run from terminal:

```bash
mysql -u root -p < schema.sql
```

### 2. Edit `config.php`

```php
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', 'your_password');
```

### 3. Copy files to your web root

```
htdocs/
  notifications/
    config.php
    notifications.php
```

### 4. Verify the endpoint works

Open in browser:
```
http://localhost/notifications/notifications.php
```

Expected response (no pending rows):
```json
{
  "success": true,
  "count": 0,
  "notifications": []
}
```

---

## Flutter side — start background polling (Windows)

```dart
final nm = NotificationMaster();

// Start the background daemon (survives app close)
await nm.startBackgroundPollingService(
  pollingUrl: 'http://localhost/notifications/notifications.php',
  intervalMinutes: 1,   // minimum 1 minute; use 1 for testing
);

// Verify it started
final running = await nm.isBackgroundPollingRunning();
print('Poller running: $running'); // true
```

Then **close the Flutter app completely** and wait up to 1 minute.
The daemon will poll the endpoint and show a Toast notification for each pending row.

---

## Insert a test notification (trigger immediately)

### Option A — phpMyAdmin

```sql
INSERT INTO notifications (title, message, big_text)
VALUES ('Test!', 'Hello from PHP server', 'This is the expanded body text shown on Windows.');
```

### Option B — cURL / Postman

```bash
curl -X POST http://localhost/notifications/notifications.php \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test from cURL",
    "message": "Short body",
    "bigText": "This is the full expanded body text."
  }'
```

### Option C — PHP script

```php
<?php
$payload = json_encode([
  'title'   => 'Server Alert',
  'message' => 'Something happened on the server.',
  'bigText' => 'Full details: the background job completed successfully at ' . date('H:i:s'),
]);

$ctx = stream_context_create(['http' => [
  'method'  => 'POST',
  'header'  => 'Content-Type: application/json',
  'content' => $payload,
]]);

$result = file_get_contents('http://localhost/notifications/notifications.php', false, $ctx);
echo $result;
```

---

## JSON response format

The endpoint returns the format the Windows C++ plugin parser expects:

```json
{
  "success": true,
  "count": 1,
  "notifications": [
    {
      "title":        "Alert",
      "message":      "Short body",
      "bigText":      "Optional longer body — shown as expanded text on Windows",
      "imageUrl":     "https://example.com/image.jpg",
      "channelId":    "high_priority_channel",
      "targetScreen": "/orders/42",
      "extraData":    { "orderId": 42 }
    }
  ]
}
```

Each row is marked `delivered_at = NOW()` the moment it is returned,
so it will **not** be sent again on the next poll.

---

## Stop background polling

```dart
await nm.stopBackgroundPollingService();
```

---

## Notes

- The Windows daemon binary (`notification_master_poller.exe`) must be present
  next to your app's `.exe` file. It is built as a separate CMake target.
- Polling interval is stored in the Windows registry under
  `HKCU\SOFTWARE\NotificationMaster\notification_master` (`bg_poll_url`, `bg_poll_interval`).
- Debug logs are written to `%TEMP%\notification_master_debug.log`.
