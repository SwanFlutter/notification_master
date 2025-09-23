<?php
/**
 * Database Connection File
 */

// Database configuration
$db_host = 'localhost';
$db_name = 'notification_db';
$db_user = 'root';
$db_pass = '';

// Create connection
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Set character set
$conn->set_charset("utf8");
?>
