-- Create the notification database
CREATE DATABASE IF NOT EXISTS notification_db;

-- Use the notification database
USE notification_db;

-- Create the notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    big_text TEXT,
    channel_id VARCHAR(100),
    is_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scheduled_at TIMESTAMP NULL
);

-- Create index for faster queries
CREATE INDEX idx_notification_status ON notifications(is_sent, scheduled_at);

-- Insert some sample notifications
INSERT INTO notifications (title, message, big_text, channel_id, scheduled_at) VALUES
('Welcome', 'Welcome to Notification Master!', 'Thank you for using Notification Master. This plugin provides easy-to-use notification functionality for Android 7+ with customizable appearance, image display, and more.', NULL, NOW()),
('High Priority', 'This is a high priority notification', 'High priority notifications appear at the top of the notification list and may show as a heads-up notification.', 'high_priority_channel', DATE_ADD(NOW(), INTERVAL 5 MINUTE)),
('Silent Notification', 'This notification is silent', 'Silent notifications do not make sound or vibrate when they arrive.', 'silent_channel', DATE_ADD(NOW(), INTERVAL 10 MINUTE)),
('Image Example', 'This notification includes an image', NULL, 'media_channel', DATE_ADD(NOW(), INTERVAL 15 MINUTE));

-- Create a user for the application (optional)
-- GRANT ALL PRIVILEGES ON notification_db.* TO 'notification_user'@'localhost' IDENTIFIED BY 'your_password';
-- FLUSH PRIVILEGES;
