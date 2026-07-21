<?php
/**
 * Notification Master — HTTP Polling Endpoint
 * ─────────────────────────────────────────────────────────────────────────────
 * GET  /notifications.php          → return pending notifications (JSON)
 * POST /notifications.php          → insert a new notification (JSON body)
 *
 * Response format (GET) — matches the Windows C++ parser in
 * NotificationMasterPlugin::ParseAndShowNotifications():
 *
 *   {
 *     "success": true,
 *     "count": 2,
 *     "notifications": [
 *       {
 *         "title":        "Alert",
 *         "message":      "Short body",
 *         "bigText":      "Optional longer body (overrides message on Windows)",
 *         "imageUrl":     "https://...",
 *         "channelId":    "high_priority_channel",
 *         "targetScreen": "/orders/42",
 *         "extraData":    {"orderId": 42}
 *       }
 *     ]
 *   }
 *
 * A row is marked delivered the moment it is returned so it is not
 * sent again on the next poll.
 * ─────────────────────────────────────────────────────────────────────────────
 */

require __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');
// Allow cross-origin requests (useful when testing from Flutter desktop/web).
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ── Database connection ───────────────────────────────────────────────────────
function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
            DB_HOST, DB_PORT, DB_NAME);
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
    }
    return $pdo;
}

function jsonError(string $msg, int $code = 500): void {
    http_response_code($code);
    echo json_encode(['success' => false, 'error' => $msg], JSON_UNESCAPED_UNICODE);
    exit;
}

// ── GET — return pending notifications ───────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $db = getDB();

        // Fetch rows that are pending AND whose deliver_after time has passed.
        $stmt = $db->prepare(
            'SELECT id, title, message, big_text, image_url,
                    channel_id, target_screen, extra_data
             FROM   notifications
             WHERE  delivered_at IS NULL
               AND  deliver_after <= NOW()
             ORDER  BY id ASC
             LIMIT  :limit'
        );
        $stmt->bindValue(':limit', MAX_PER_POLL, PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll();

        if (empty($rows)) {
            // Return an empty array — the plugin will show nothing.
            echo json_encode([
                'success'       => true,
                'count'         => 0,
                'notifications' => [],
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            exit;
        }

        // Mark them as delivered so they are not resent.
        $ids = array_column($rows, 'id');
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $db->prepare("UPDATE notifications SET delivered_at = NOW() WHERE id IN ($placeholders)")
           ->execute($ids);

        // Build response array in the format the plugin expects.
        $notifications = [];
        foreach ($rows as $row) {
            $n = [
                'title'   => $row['title'],
                'message' => $row['message'],
            ];
            // bigText — camelCase as expected by Windows C++ parser and iOS/macOS Swift
            if (!empty($row['big_text'])) {
                $n['bigText'] = $row['big_text'];
            }
            if (!empty($row['image_url'])) {
                $n['imageUrl'] = $row['image_url'];
            }
            if (!empty($row['channel_id'])) {
                $n['channelId'] = $row['channel_id'];
            }
            if (!empty($row['target_screen'])) {
                $n['targetScreen'] = $row['target_screen'];
            }
            if (!empty($row['extra_data'])) {
                $decoded = json_decode($row['extra_data'], true);
                if ($decoded !== null) {
                    $n['extraData'] = $decoded;
                }
            }
            $notifications[] = $n;
        }

        echo json_encode([
            'success'       => true,
            'count'         => count($notifications),
            'notifications' => $notifications,
        ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

    } catch (PDOException $e) {
        $msg = DEBUG_MODE ? $e->getMessage() : 'Database error';
        jsonError($msg);
    }
    exit;
}

// ── POST — insert a new notification ─────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = file_get_contents('php://input');
    $data = json_decode($body, true);

    if (!$data || empty($data['title']) || empty($data['message'])) {
        jsonError('title and message are required', 400);
    }

    try {
        $db = getDB();
        $stmt = $db->prepare(
            'INSERT INTO notifications
               (title, message, big_text, image_url, channel_id,
                target_screen, extra_data, deliver_after)
             VALUES
               (:title, :message, :big_text, :image_url, :channel_id,
                :target_screen, :extra_data, :deliver_after)'
        );
        $stmt->execute([
            ':title'         => $data['title'],
            ':message'       => $data['message'],
            ':big_text'      => $data['bigText']      ?? $data['big_text']      ?? null,
            ':image_url'     => $data['imageUrl']     ?? $data['image_url']     ?? null,
            ':channel_id'    => $data['channelId']    ?? $data['channel_id']    ?? null,
            ':target_screen' => $data['targetScreen'] ?? $data['target_screen'] ?? null,
            ':extra_data'    => isset($data['extraData']) ? json_encode($data['extraData']) : null,
            ':deliver_after' => $data['deliverAfter'] ?? date('Y-m-d H:i:s'),
        ]);

        echo json_encode([
            'success' => true,
            'id'      => (int) $db->lastInsertId(),
        ], JSON_UNESCAPED_UNICODE);

    } catch (PDOException $e) {
        $msg = DEBUG_MODE ? $e->getMessage() : 'Database error';
        jsonError($msg);
    }
    exit;
}

jsonError('Method not allowed', 405);
