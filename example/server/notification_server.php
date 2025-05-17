<?php
/**
 * Notification Server for Android Notification Plugin
 * 
 * This script provides a simple API for sending notifications to Android devices.
 * It includes:
 * 1. Database setup for storing notifications
 * 2. API endpoint for retrieving notifications
 * 3. Cron job setup for sending periodic notifications
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
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

// Create notifications table if it doesn't exist
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        big_text TEXT,
        channel_id VARCHAR(100),
        is_sent BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        scheduled_at TIMESTAMP NULL
    )");
} catch (PDOException $e) {
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Table creation failed: ' . $e->getMessage()]);
    exit;
}

// Handle API requests
$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Get notifications
        getNotifications();
        break;
    case 'POST':
        // Add a new notification
        addNotification();
        break;
    case 'PUT':
        // Update notification status
        updateNotificationStatus();
        break;
    default:
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Invalid request method']);
        break;
}

/**
 * Get notifications that are due to be sent
 */
function getNotifications() {
    global $pdo;
    
    try {
        // Get notifications that are scheduled for now or earlier and not yet sent
        $stmt = $pdo->prepare("
            SELECT id, title, message, big_text, channel_id 
            FROM notifications 
            WHERE (scheduled_at IS NULL OR scheduled_at <= NOW()) 
            AND is_sent = FALSE
            LIMIT 10
        ");
        $stmt->execute();
        $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format the response
        $response = ['notifications' => []];
        foreach ($notifications as $notification) {
            $item = [
                'title' => $notification['title'],
                'message' => $notification['message']
            ];
            
            if (!empty($notification['big_text'])) {
                $item['bigText'] = $notification['big_text'];
            }
            
            if (!empty($notification['channel_id'])) {
                $item['channelId'] = $notification['channel_id'];
            }
            
            $response['notifications'][] = $item;
            
            // Mark as sent
            $updateStmt = $pdo->prepare("UPDATE notifications SET is_sent = TRUE WHERE id = ?");
            $updateStmt->execute([$notification['id']]);
        }
        
        header('Content-Type: application/json');
        echo json_encode($response);
    } catch (PDOException $e) {
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Failed to get notifications: ' . $e->getMessage()]);
    }
}

/**
 * Add a new notification
 */
function addNotification() {
    global $pdo;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['title']) || !isset($data['message'])) {
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Title and message are required']);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO notifications (title, message, big_text, channel_id, scheduled_at) 
            VALUES (?, ?, ?, ?, ?)
        ");
        
        $scheduledAt = isset($data['scheduled_at']) ? $data['scheduled_at'] : null;
        
        $stmt->execute([
            $data['title'],
            $data['message'],
            $data['big_text'] ?? null,
            $data['channel_id'] ?? null,
            $scheduledAt
        ]);
        
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'id' => $pdo->lastInsertId()]);
    } catch (PDOException $e) {
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Failed to add notification: ' . $e->getMessage()]);
    }
}

/**
 * Update notification status
 */
function updateNotificationStatus() {
    global $pdo;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id'])) {
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Notification ID is required']);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("UPDATE notifications SET is_sent = ? WHERE id = ?");
        $stmt->execute([$data['is_sent'] ?? true, $data['id']]);
        
        header('Content-Type: application/json');
        echo json_encode(['success' => true]);
    } catch (PDOException $e) {
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Failed to update notification: ' . $e->getMessage()]);
    }
}
?>
