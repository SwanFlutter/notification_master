<?php
/**
 * Simple Notification Server for Android Notification Plugin
 * 
 * This is a simplified version that doesn't require a database.
 * It randomly generates notifications for testing purposes.
 */

// Set headers to allow cross-origin requests
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Only handle GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Sample notifications
$notifications = [
    [
        'title' => 'Welcome Notification',
        'message' => 'Thank you for testing the notification system',
        'bigText' => 'This is an expanded text that will be shown when the notification is expanded. It can contain much more content than the regular message.',
        'channelId' => 'high_priority_channel'
    ],
    [
        'title' => 'Test Notification',
        'message' => 'This is a test notification from the local server',
        'channelId' => 'media_channel'
    ],
    [
        'title' => 'Image Notification',
        'message' => 'This notification includes an image',
        'imageUrl' => 'https://picsum.photos/id/237/200/300',
        'channelId' => 'media_channel'
    ]
];

// Randomly decide whether to send notifications or empty response
$shouldSendNotifications = (rand(0, 1) === 1);

// Prepare response
$response = [
    'notifications' => $shouldSendNotifications 
        ? [$notifications[array_rand($notifications)]] 
        : []
];

// Log request (if running from command line)
if (php_sapi_name() === 'cli-server') {
    $status = $shouldSendNotifications ? 'with notification' : 'empty';
    error_log("Received request: " . $_SERVER['REQUEST_URI'] . " - Sent response: $status");
}

// Send JSON response
echo json_encode($response);
?>
