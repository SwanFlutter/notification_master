# Notification Server

This directory contains server-side code for the Notification Master plugin example. It demonstrates how to set up a server that sends notifications to Android devices using HTTP/JSON.

## Server Options

### 1. Simple Server (simple_notification_server.php)
A basic server that randomly generates notifications without requiring a database. This is perfect for quick testing.

### 2. Full Server (notification_server.php)
A more complete implementation with database support for storing and managing notifications.

## Simple Server Setup

1. Make sure you have PHP installed on your system
2. Open a terminal in this directory
3. Run the PHP built-in web server:
   ```
   php -S localhost:3000 simple_notification_server.php
   ```
4. The server will start on http://localhost:3000/

## Full Server Setup

1. **Database Setup**
   - Create a MySQL database using the `setup_database.sql` script:
   ```bash
   mysql -u root -p < setup_database.sql
   ```
   - This will create a database named `notification_db` with a `notifications` table and some sample data.

2. **Server Setup**
   - Place the PHP files in your web server directory (e.g., Apache, Nginx).
   - Make sure PHP and MySQL are installed and configured.
   - Update the database connection details in both PHP files if needed.

3. **Cron Job Setup**
   - To create a notification every minute, set up a cron job:
   ```bash
   crontab -e
   ```
   - Add the following line:
   ```
   * * * * * php /path/to/create_minute_notification.php
   ```
   - This will run the script every minute, creating a new notification.

## API Endpoints

### GET /notification_server.php
Retrieves notifications that are due to be sent.

**Response:**
```json
{
  "notifications": [
    {
      "title": "Notification Title",
      "message": "Notification Message",
      "bigText": "Optional expanded text",
      "channelId": "Optional custom channel ID"
    }
  ]
}
```

### POST /notification_server.php
Creates a new notification.

**Request Body:**
```json
{
  "title": "Notification Title",
  "message": "Notification Message",
  "big_text": "Optional expanded text",
  "channel_id": "Optional custom channel ID",
  "scheduled_at": "2023-06-01 12:00:00"
}
```

**Response:**
```json
{
  "success": true,
  "id": 123
}
```

### PUT /notification_server.php
Updates a notification's status.

**Request Body:**
```json
{
  "id": 123,
  "is_sent": true
}
```

**Response:**
```json
{
  "success": true
}
```

## Testing

### Testing with the Simple Server
1. Start the simple server:
   ```
   php -S localhost:3000 simple_notification_server.php
   ```
2. Configure the Flutter app to use the simple server URL:
   ```dart
   await notificationMaster.startNotificationPolling(
     pollingUrl: 'http://10.0.2.2:3000/', // For Android emulator
     // OR
     // pollingUrl: 'http://YOUR_COMPUTER_IP:3000/', // For physical device
     intervalMinutes: 1, // Poll every minute for testing
   );
   ```
3. Run the Flutter app and check for notifications.

### Testing with the Full Server
1. Start your web server with the full implementation.
2. Configure the Flutter app to use your server URL:
   ```dart
   await notificationMaster.startNotificationPolling(
     pollingUrl: 'http://your-server.com/notification_server.php',
     intervalMinutes: 1, // Poll every minute for testing
   );
   ```
3. Run the Flutter app and check for notifications.

## Notes

- This is a simple implementation for demonstration purposes.
- In a production environment, you should:
  - Implement proper authentication
  - Use HTTPS
  - Add error handling and logging
  - Consider using a more robust architecture (e.g., a framework like Laravel)
