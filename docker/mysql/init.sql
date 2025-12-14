-- ======================================
-- MySQL Initialization Script
-- ======================================

USE app_db;

-- Create example table
CREATE TABLE IF NOT EXISTS app_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    info_key VARCHAR(255) NOT NULL UNIQUE,
    info_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert sample data
INSERT INTO app_info (info_key, info_value) VALUES
    ('app_name', 'PHP Containerization PoC'),
    ('version', '1.0.0'),
    ('environment', 'Docker Container'),
    ('database', 'MySQL 8.0'),
    ('cache', 'Redis 7')
ON DUPLICATE KEY UPDATE info_value = VALUES(info_value);

-- Create health check table
CREATE TABLE IF NOT EXISTS health_checks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    check_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'OK'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO health_checks (status) VALUES ('INITIALIZED');
