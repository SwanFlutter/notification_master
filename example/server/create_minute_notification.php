<?php
/**
 * Create Minute Notification Script
 *
 * This script creates a new notification every minute.
 * It should be run as a cron job with the following schedule:
 * * * * * * php /path/to/create_minute_notification.php
 */

// Database configuration
$db_host = 'localhost';
$db_name = 'notification_db';
$db_user = 'root';
$db_pass = '';

// Connect to database
try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo "Database connection failed: " . $e->getMessage() . "\n";
    exit;
}

// Create a new notification
try {
    // Current time
    $now = date('Y-m-d H:i:s');

    // Create notification content
    $title = "Minute Update";
    $message = "Notification at " . date('H:i:s');
    $bigText = "This is an automatic notification created at " . $now . ". " .
               "These notifications are sent every minute to demonstrate the HTTP notification polling feature.";

    // Define channels with different priorities
    $channels = [
        'high_priority_channel',  // High priority with sound
        'default_channel',        // Default priority with sound
        'silent_channel',         // Silent notification
        'media_channel'           // Media notification
    ];

    // Use a random channel for variety
    $channelId = $channels[array_rand($channels)];

    // Insert the notification
    $stmt = $pdo->prepare("
        INSERT INTO notifications (title, message, big_text, channel_id, scheduled_at)
        VALUES (?, ?, ?, ?, ?)
    ");

    $stmt->execute([
        $title,
        $message,
        $bigText,
        $channelId,
        $now // Schedule for immediate delivery
    ]);

    echo "Created notification: $title - $message\n";
} catch (PDOException $e) {
    echo "Failed to create notification: " . $e->getMessage() . "\n";
}
?>
