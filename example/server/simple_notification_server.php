<?php
/**
 * Simple Notification Server for Android Notification Plugin
 *
 * This script provides a simple API for sending notifications to Android devices.
 * It uses mysqli and has a simpler implementation.
 */

// Database configuration
include_once('connection.php'); // Make sure this file exists and defines $conn

// Set headers to allow cross-origin requests
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Create notifications table if it doesn't exist
$create_table_sql = "CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    big_text TEXT,
    channel_id VARCHAR(100),
    is_sent TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";
$conn->query($create_table_sql);

// Check if we have any notifications at all
$check_total_sql = "SELECT COUNT(*) as count FROM notifications";
$check_total_result = $conn->query($check_total_sql);
$check_total_row = $check_total_result->fetch_assoc();

// If no notifications exist, create some sample ones
if ($check_total_row['count'] == 0) {
    $channels = ['high_priority_channel', 'default_channel', 'silent_channel', 'media_channel'];

    for ($i = 1; $i <= 10; $i++) {
        $title = "Notification #$i";
        $message = "This is notification message #$i";
        $big_text = "This is an expanded text for notification #$i. It contains more details about the notification.";
        $channel_id = $channels[array_rand($channels)];

        $insert_sql = "INSERT INTO notifications (title, message, big_text, channel_id)
                      VALUES ('$title', '$message', '$big_text', '$channel_id')";
        $conn->query($insert_sql);
    }
}

// Check if we have any unsent notifications
$check_sql = "SELECT COUNT(*) as count FROM notifications WHERE is_sent = 0";
$check_result = $conn->query($check_sql);
$check_row = $check_result->fetch_assoc();

// If no unsent notifications, reset all to unsent
if ($check_row['count'] == 0) {
    $reset_sql = "UPDATE notifications SET is_sent = 0";
    $conn->query($reset_sql);
}

// Get one notification that is not yet sent
$sql = "SELECT * FROM notifications WHERE is_sent = 0 ORDER BY id ASC LIMIT 1";
$result = $conn->query($sql);

$response = ['notifications' => []];

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();

    // Format the notification
    $notification = [
        'title' => $row['title'],
        'message' => $row['message']
    ];

    // Add optional fields if they exist
    if (!empty($row['big_text'])) {
        $notification['bigText'] = $row['big_text'];
    }

    if (!empty($row['channel_id'])) {
        $notification['channelId'] = $row['channel_id'];
    }

    $response['notifications'][] = $notification;

    // Mark as sent
    $update_sql = "UPDATE notifications SET is_sent = 1 WHERE id = " . $row['id'];
    $conn->query($update_sql);
}

// Return the response
echo json_encode($response);

$conn->close();
?>
