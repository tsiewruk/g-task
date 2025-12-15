<?php

namespace Tests\Unit;

use App\Helper;
use PHPUnit\Framework\TestCase;

/**
 * Unit tests for environment validation
 */
class EnvironmentTest extends TestCase
{
    /**
     * Store original environment state
     *
     * @var array
     */
    private array $originalEnv = [];

    /**
     * Set up test environment
     *
     * @return void
     */
    protected function setUp(): void
    {
        parent::setUp();

        // Store original env vars to restore later
        $this->originalEnv = [
            'TEST_VAR_1' => getenv('TEST_VAR_1'),
            'TEST_VAR_2' => getenv('TEST_VAR_2'),
            'TEST_VAR_3' => getenv('TEST_VAR_3'),
        ];
    }

    /**
     * Restore original environment
     *
     * @return void
     */
    protected function tearDown(): void
    {
        // Restore original environment
        foreach ($this->originalEnv as $key => $value) {
            if ($value === false) {
                putenv($key);
            } else {
                putenv("{$key}={$value}");
            }
        }

        parent::tearDown();
    }

    /**
     * Test validateEnvironment returns valid when all vars are set
     *
     * @return void
     */
    public function testValidateEnvironmentReturnsValidWhenAllVarsSet(): void
    {
        // Set test environment variables
        putenv('TEST_VAR_1=value1');
        putenv('TEST_VAR_2=value2');

        $result = Helper::validateEnvironment(['TEST_VAR_1', 'TEST_VAR_2']);

        $this->assertTrue($result['valid']);
        $this->assertEmpty($result['missing']);
    }

    /**
     * Test validateEnvironment detects missing variables
     *
     * @return void
     */
    public function testValidateEnvironmentDetectsMissingVars(): void
    {
        // Ensure TEST_VAR_3 is not set
        putenv('TEST_VAR_3');

        $result = Helper::validateEnvironment(['TEST_VAR_1', 'TEST_VAR_3']);

        $this->assertFalse($result['valid']);
        $this->assertContains('TEST_VAR_3', $result['missing']);
    }

    /**
     * Test validateEnvironment detects empty string as missing
     *
     * @return void
     */
    public function testValidateEnvironmentDetectsEmptyString(): void
    {
        // Set empty value
        putenv('TEST_VAR_1=');

        $result = Helper::validateEnvironment(['TEST_VAR_1']);

        $this->assertFalse($result['valid']);
        $this->assertContains('TEST_VAR_1', $result['missing']);
    }

    /**
     * Test validateEnvironment with multiple missing vars
     *
     * @return void
     */
    public function testValidateEnvironmentWithMultipleMissingVars(): void
    {
        // Unset test variables
        putenv('TEST_VAR_1');
        putenv('TEST_VAR_2');

        $result = Helper::validateEnvironment(['TEST_VAR_1', 'TEST_VAR_2', 'TEST_VAR_3']);

        $this->assertFalse($result['valid']);
        $this->assertCount(3, $result['missing']);
        $this->assertContains('TEST_VAR_1', $result['missing']);
        $this->assertContains('TEST_VAR_2', $result['missing']);
    }

    /**
     * Test validateEnvironment with empty array
     *
     * @return void
     */
    public function testValidateEnvironmentWithEmptyArray(): void
    {
        $result = Helper::validateEnvironment([]);

        $this->assertTrue($result['valid']);
        $this->assertEmpty($result['missing']);
    }

    /**
     * Test validateEnvironment returns proper structure
     *
     * @return void
     */
    public function testValidateEnvironmentReturnsProperStructure(): void
    {
        $result = Helper::validateEnvironment(['ANY_VAR']);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('valid', $result);
        $this->assertArrayHasKey('missing', $result);
        $this->assertIsBool($result['valid']);
        $this->assertIsArray($result['missing']);
    }
}
