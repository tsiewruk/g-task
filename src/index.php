<?php
/**
 * PoC Aplikacji PHP - Konteneryzacja
 *
 * Demonstracja działania PHP 8.x z rozszerzeniami PDO MySQL i Redis
 */

// Simple logger function
function logMessage($level, $message, $context = []) {
    $timestamp = date('Y-m-d H:i:s');
    $contextStr = !empty($context) ? json_encode($context) : '';
    echo "[{$timestamp}] {$level}: {$message} {$contextStr}\n";
}

?>
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Containerization PoC</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }
        h2 {
            color: #555;
            margin-top: 30px;
        }
        .status {
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
        }
        .success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .info {
            background: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        table th {
            background: #4CAF50;
            color: white;
            padding: 12px;
            text-align: left;
        }
        table td {
            padding: 10px;
            border-bottom: 1px solid #ddd;
        }
        table tr:hover {
            background: #f5f5f5;
        }
        code {
            background: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
        .badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: bold;
        }
        .badge-success {
            background: #28a745;
            color: white;
        }
        .badge-danger {
            background: #dc3545;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐘 PHP Containerization PoC</h1>
        <p>Proof of Concept konteneryzacji aplikacji PHP z Apache, MySQL, Redis i Traefik</p>

        <h2>📋 Informacje podstawowe</h2>
        <table>
            <tr>
                <th>Parametr</th>
                <th>Wartość</th>
            </tr>
            <tr>
                <td>Wersja PHP</td>
                <td><code><?php echo PHP_VERSION; ?></code></td>
            </tr>
            <tr>
                <td>Serwer</td>
                <td><code><?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?></code></td>
            </tr>
            <tr>
                <td>Nazwa hosta</td>
                <td><code><?php echo gethostname(); ?></code></td>
            </tr>
            <tr>
                <td>Document Root</td>
                <td><code><?php echo $_SERVER['DOCUMENT_ROOT'] ?? 'Unknown'; ?></code></td>
            </tr>
        </table>

        <h2>🔌 Status rozszerzeń PHP</h2>
        <table>
            <tr>
                <th>Rozszerzenie</th>
                <th>Status</th>
                <th>Wersja</th>
            </tr>
            <?php
            $extensions = [
                'pdo' => 'PDO',
                'pdo_mysql' => 'PDO MySQL',
                'redis' => 'Redis',
                'xdebug' => 'Xdebug (dev only)'
            ];

            foreach ($extensions as $ext => $name) {
                $loaded = extension_loaded($ext);
                $version = $loaded ? phpversion($ext) : 'N/A';
                $badge = $loaded ? 'badge-success' : 'badge-danger';
                $status = $loaded ? '✓ Załadowane' : '✗ Brak';

                echo "<tr>";
                echo "<td>{$name}</td>";
                echo "<td><span class='badge {$badge}'>{$status}</span></td>";
                echo "<td><code>{$version}</code></td>";
                echo "</tr>";
            }
            ?>
        </table>

        <h2>🗄️ Test połączenia z MySQL</h2>
        <?php
        try {
            $mysqlHost = getenv('MYSQL_HOST') ?: 'mysql';
            $mysqlDb = getenv('MYSQL_DATABASE') ?: 'app_db';
            $mysqlUser = getenv('MYSQL_USER') ?: 'app_user';
            $mysqlPass = getenv('MYSQL_PASSWORD') ?: 'app_password';

            $dsn = "mysql:host={$mysqlHost};dbname={$mysqlDb};charset=utf8mb4";
            $pdo = new PDO($dsn, $mysqlUser, $mysqlPass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]);

            $stmt = $pdo->query('SELECT VERSION() as version, NOW() as server_time');
            $result = $stmt->fetch();

            echo '<div class="status success">';
            echo '✓ Połączenie z MySQL nawiązane pomyślnie<br>';
            echo 'Wersja MySQL: <code>' . htmlspecialchars($result['version']) . '</code><br>';
            echo 'Czas serwera: <code>' . htmlspecialchars($result['server_time']) . '</code>';
            echo '</div>';

            logMessage('INFO', 'MySQL connection successful', ['version' => $result['version']]);
        } catch (PDOException $e) {
            echo '<div class="status error">';
            echo '✗ Błąd połączenia z MySQL: ' . htmlspecialchars($e->getMessage());
            echo '</div>';
            logMessage('ERROR', 'MySQL connection failed', ['error' => $e->getMessage()]);
        }
        ?>

        <h2>🔴 Test połączenia z Redis</h2>
        <?php
        try {
            $redisHost = getenv('REDIS_HOST') ?: 'redis';
            $redisPort = getenv('REDIS_PORT') ?: 6379;

            $redis = new Redis();
            $redis->connect($redisHost, (int)$redisPort);

            // Test zapisu i odczytu
            $testKey = 'poc_test_' . time();
            $testValue = 'PoC Value - ' . date('Y-m-d H:i:s');
            $redis->setex($testKey, 60, $testValue);
            $retrievedValue = $redis->get($testKey);

            $redisInfo = $redis->info('server');

            echo '<div class="status success">';
            echo '✓ Połączenie z Redis nawiązane pomyślnie<br>';
            echo 'Wersja Redis: <code>' . htmlspecialchars($redisInfo['redis_version'] ?? 'Unknown') . '</code><br>';
            echo 'Test zapisu/odczytu: <code>' . htmlspecialchars($retrievedValue) . '</code>';
            echo '</div>';

            logMessage('INFO', 'Redis connection successful', ['version' => $redisInfo['redis_version'] ?? 'Unknown']);
        } catch (Exception $e) {
            echo '<div class="status error">';
            echo '✗ Błąd połączenia z Redis: ' . htmlspecialchars($e->getMessage());
            echo '</div>';
            logMessage('ERROR', 'Redis connection failed', ['error' => $e->getMessage()]);
        }
        ?>

        <h2>🌍 Zmienne środowiskowe (z /etc/environment)</h2>
        <table>
            <tr>
                <th>Nazwa zmiennej</th>
                <th>Wartość</th>
            </tr>
            <?php
            $envVars = [
                'APP_ENV',
                'APP_NAME',
                'APP_DEBUG',
                'MYSQL_HOST',
                'MYSQL_DATABASE',
                'MYSQL_USER',
                'REDIS_HOST',
                'REDIS_PORT'
            ];

            foreach ($envVars as $var) {
                $value = getenv($var);
                $displayValue = $value !== false ? htmlspecialchars($value) : '<em>nie ustawiona</em>';

                // Maskowanie wrażliwych danych
                if (strpos($var, 'PASSWORD') !== false && $value !== false) {
                    $displayValue = str_repeat('*', strlen($value));
                }

                echo "<tr>";
                echo "<td><code>{$var}</code></td>";
                echo "<td>{$displayValue}</td>";
                echo "</tr>";
            }
            ?>
        </table>

        <h2>📊 Pełne PHP Info</h2>
        <div class="info">
            Kliknij <a href="?phpinfo=1" target="_blank">tutaj</a> aby zobaczyć pełne phpinfo()
        </div>
    </div>
</body>
</html>

<?php
// Jeśli żądane phpinfo, wyświetl je
if (isset($_GET['phpinfo'])) {
    phpinfo();
    exit;
}
?>
