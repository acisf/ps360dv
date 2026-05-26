/**
 * Utility class for basic mathematical operations.
 * All methods are static and side-effect-free (no SOQL, no DML).
 * Private constructor prevents instantiation.
 */
public with sharing class CalculatorUtil {

    // ─── Private Constructor ─────────────────────────────────────────────

    /**
     * Prevents instantiation — use static methods only
     */
    @TestVisible
    private CalculatorUtil() {
        // Utility class — do not instantiate
    }

    // ─── Public Methods ──────────────────────────────────────────────────

    /**
     * Adds two integers together
     * @param a The first number
     * @param b The second number
     * @return The sum of a and b
     * @example
     * Integer result = CalculatorUtil.add(1, 1); // returns 2
     */
    public static Integer add(Integer a, Integer b) {
        if (a == null) {
            a = 0;
        }
        if (b == null) {
            b = 0;
        }
        return a + b;
    }

    /**
     * Convenience method that adds 1 + 1
     * @return 2
     * @example
     * Integer result = CalculatorUtil.addOnePlusOne(); // returns 2
     */
    public static Integer addOnePlusOne() {
        return add(1, 1);
    }
}