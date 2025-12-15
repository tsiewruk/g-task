<?php

namespace Tests\Unit;

use App\Helper;
use PHPUnit\Framework\TestCase;

/**
 * Unit tests for Helper class
 */
class HelperTest extends TestCase
{
    /**
     * Test logMessage returns properly formatted log string
     *
     * @return void
     */
    public function testLogMessageReturnsFormattedString(): void
    {
        $level = 'INFO';
        $message = 'Test message';
        $context = ['user_id' => 123, 'action' => 'login'];

        $result = Helper::logMessage($level, $message, $context);

        // Check that result contains all expected elements
        $this->assertStringContainsString($level, $result);
        $this->assertStringContainsString($message, $result);
        $this->assertStringContainsString('"user_id":123', $result);
        $this->assertStringContainsString('"action":"login"', $result);

        // Check format with timestamp pattern [YYYY-MM-DD HH:MM:SS]
        $this->assertMatchesRegularExpression('/^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/', $result);
    }

    /**
     * Test logMessage works without context
     *
     * @return void
     */
    public function testLogMessageWithoutContext(): void
    {
        $level = 'ERROR';
        $message = 'Error occurred';

        $result = Helper::logMessage($level, $message);

        $this->assertStringContainsString($level, $result);
        $this->assertStringContainsString($message, $result);
        $this->assertMatchesRegularExpression('/^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/', $result);
    }

    /**
     * Test logMessage handles empty context array
     *
     * @return void
     */
    public function testLogMessageWithEmptyContext(): void
    {
        $result = Helper::logMessage('DEBUG', 'Debug info', []);

        $this->assertStringContainsString('DEBUG', $result);
        $this->assertStringContainsString('Debug info', $result);
    }

    /**
     * Test maskSensitiveData masks password correctly
     *
     * @return void
     */
    public function testMaskSensitiveDataMasksCorrectly(): void
    {
        $password = 'MySecretPassword123';
        $masked = Helper::maskSensitiveData($password, 2);

        // Should show first 2 and last 2 characters
        $this->assertStringStartsWith('My', $masked);
        $this->assertStringEndsWith('23', $masked);
        $this->assertStringContainsString('***', $masked);

        // Check total length is preserved
        $this->assertEquals(strlen($password), strlen($masked));
    }

    /**
     * Test maskSensitiveData handles short strings
     *
     * @return void
     */
    public function testMaskSensitiveDataHandlesShortStrings(): void
    {
        $short = 'abc';
        $masked = Helper::maskSensitiveData($short, 2);

        // Should be fully masked for short strings
        $this->assertEquals('***', $masked);
        $this->assertEquals(strlen($short), strlen($masked));
    }

    /**
     * Test maskSensitiveData with different visible chars
     *
     * @return void
     */
    public function testMaskSensitiveDataWithDifferentVisibleChars(): void
    {
        $apiKey = 'sk-1234567890abcdef';
        $masked = Helper::maskSensitiveData($apiKey, 3);

        $this->assertStringStartsWith('sk-', $masked);
        $this->assertStringEndsWith('def', $masked);
        $this->assertStringContainsString('***', $masked);
    }
}
