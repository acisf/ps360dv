/**
 * Test class for CalculatorUtil.
 * Tests basic arithmetic operations, null handling, and edge cases.
 */
@isTest
private class CalculatorUtilTest {

    // ─── Positive Tests ───────────────────────────────────────────────────

    @isTest
    static void shouldReturnTwo_WhenAddingOnePlusOne() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(1, 1);
        Test.stopTest();

        // Then
        Assert.areEqual(2, result, 'Adding 1 + 1 should return 2');
    }

    @isTest
    static void shouldReturnTwo_WhenUsingAddOnePlusOne() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.addOnePlusOne();
        Test.stopTest();

        // Then
        Assert.areEqual(2, result, 'addOnePlusOne() should return 2');
    }

    @isTest
    static void shouldReturnCorrectSum_WhenAddingPositiveNumbers() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(5, 10);
        Test.stopTest();

        // Then
        Assert.areEqual(15, result, 'Adding 5 + 10 should return 15');
    }

    @isTest
    static void shouldReturnCorrectSum_WhenAddingNegativeNumbers() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(-5, -10);
        Test.stopTest();

        // Then
        Assert.areEqual(-15, result, 'Adding -5 + -10 should return -15');
    }

    @isTest
    static void shouldReturnCorrectSum_WhenAddingMixedSignNumbers() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(10, -3);
        Test.stopTest();

        // Then
        Assert.areEqual(7, result, 'Adding 10 + -3 should return 7');
    }

    @isTest
    static void shouldReturnZero_WhenAddingZeros() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(0, 0);
        Test.stopTest();

        // Then
        Assert.areEqual(0, result, 'Adding 0 + 0 should return 0');
    }

    // ─── Null Handling Tests ──────────────────────────────────────────────

    @isTest
    static void shouldReturnSecondValue_WhenFirstParameterIsNull() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(null, 5);
        Test.stopTest();

        // Then
        Assert.areEqual(5, result, 'Null first parameter should be treated as 0');
    }

    @isTest
    static void shouldReturnFirstValue_WhenSecondParameterIsNull() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(5, null);
        Test.stopTest();

        // Then
        Assert.areEqual(5, result, 'Null second parameter should be treated as 0');
    }

    @isTest
    static void shouldReturnZero_WhenBothParametersAreNull() {
        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(null, null);
        Test.stopTest();

        // Then
        Assert.areEqual(0, result, 'Both null parameters should be treated as 0');
    }

    // ─── Edge Case Tests ──────────────────────────────────────────────────

    @isTest
    static void shouldHandleLargeNumbers_WhenAddingMaxIntegers() {
        // Given
        Integer maxInt = 2147483647; // Maximum 32-bit signed integer

        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(maxInt, 0);
        Test.stopTest();

        // Then
        Assert.areEqual(maxInt, result, 'Should handle maximum integer value');
    }

    @isTest
    static void shouldHandleMinimumInteger_WhenAddingMinIntegers() {
        // Given
        Integer minInt = -2147483647 - 1; // Minimum 32-bit signed integer

        // When
        Test.startTest();
        Integer result = CalculatorUtil.add(minInt, 0);
        Test.stopTest();

        // Then
        Assert.areEqual(minInt, result, 'Should handle minimum integer value');
    }
}