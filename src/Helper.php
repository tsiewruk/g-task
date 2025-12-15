<?php

namespace App;

/**
 * Helper class for common utility functions
 */
class Helper
{
    /**
     * Log a message with timestamp and context
     *
     * @param string $level Log level (INFO, ERROR, WARNING, DEBUG)
     * @param string $message Log message
     * @param array $context Additional context data
     * @return string Formatted log message
     */
    public static function logMessage(string $level, string $message, array $context = []): string
    {
        $timestamp = date('Y-m-d H:i:s');
        $contextStr = !empty($context) ? json_encode($context) : '';
        return "[{$timestamp}] {$level}: {$message} {$contextStr}";
    }

    /**
     * Validate required environment variables
     *
     * @param array $requiredVars Array of required environment variable names
     * @return array Array with 'valid' boolean and 'missing' array of missing vars
     */
    public static function validateEnvironment(array $requiredVars): array
    {
        $missing = [];

        foreach ($requiredVars as $var) {
            if (getenv($var) === false || getenv($var) === '') {
                $missing[] = $var;
            }
        }

        return [
            'valid' => empty($missing),
            'missing' => $missing
        ];
    }

    /**
     * Mask sensitive data in strings
     *
     * @param string $value Value to mask
     * @param int $visibleChars Number of characters to keep visible at start and end
     * @return string Masked value
     */
    public static function maskSensitiveData(string $value, int $visibleChars = 2): string
    {
        $length = strlen($value);

        if ($length <= $visibleChars * 2) {
            return str_repeat('*', $length);
        }

        $start = substr($value, 0, $visibleChars);
        $end = substr($value, -$visibleChars);
        $middle = str_repeat('*', $length - ($visibleChars * 2));

        return $start . $middle . $end;
    }
}
