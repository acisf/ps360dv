@isTest
private class ScheduleBatchPracticeInfoRequestsTest {
    
    @isTest
    static void testScheduler() {
        
        // Schedule the batch job
        String cronExp = '0 0 23 * * ?'; // Run every day at 11 PM
        String jobName = 'Test ScheduleBatchPracticeInfoRequests Job';

        Test.startTest();
        // Schedule the batch job
        Id jobId = System.schedule(jobName, cronExp, new ScheduleBatchPracticeInfoRequests());
        Test.stopTest();
        
        // Verify the job has been scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match the scheduled expression.');
        System.assertEquals('WAITING', ct.State, 'The job should be in a WAITING state after being scheduled.');
    }
}