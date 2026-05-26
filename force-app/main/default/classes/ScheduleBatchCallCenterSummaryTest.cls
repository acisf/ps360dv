@isTest
private class ScheduleBatchCallCenterSummaryTest {
    @isTest
    static void testJobIsScheduled() {
        Test.startTest();
            String jobId = System.schedule(
                'Test Scheduled Batch',
                '0 0 12 * * ?',  
                new ScheduleBatchCallCenterSummary()
            );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }
}