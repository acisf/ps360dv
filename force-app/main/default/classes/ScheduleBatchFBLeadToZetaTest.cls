@isTest
private class ScheduleBatchFBLeadToZetaTest {
    
    @isTest
    static void testScheduling() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Scheduled Job',
            '0 0 6 * * ?', // 6:00 AM daily
            new ScheduleBatchFBLeadToZeta()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Expected a valid job ID to be returned when scheduling.');
    }
}