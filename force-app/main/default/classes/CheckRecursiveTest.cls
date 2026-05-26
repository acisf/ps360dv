@IsTest
public class CheckRecursiveTest {
    
    @IsTest
    static void testSubsequentCalls() {
        // First call to runOnce() should return true
        Boolean firstRunResult = CheckRecursive.runOnce();
        System.assertEquals(true, firstRunResult, 'First call to runOnce() should return true');
        
        // Verify that the subsequent call to runOnce() returns false
        Boolean secondRunResult = CheckRecursive.runOnce();
        System.assertEquals(false, secondRunResult, 'Second call to runOnce() should return false');
        
        // Verify that additional calls to runOnce() also return false
        Boolean thirdRunResult = CheckRecursive.runOnce();
        System.assertEquals(false, thirdRunResult, 'Third call to runOnce() should return false');
    }
}