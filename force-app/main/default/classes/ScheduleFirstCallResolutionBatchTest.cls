@isTest
public class ScheduleFirstCallResolutionBatchTest {
    
    @isTest
    static void testSchedulableExecution() {
        // Schedule the test job
        String jobId = System.schedule('Test_ScheduleFirstCallResolutionBatch', '0 0 0 * * ?', new ScheduleFirstCallResolutionBatch());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals('0 0 0 * * ?', ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Calculate the expected next execution time (midnight of the next day)
        Datetime expectedNextFireTime = DateTime.newInstance(DateTime.now().year(), DateTime.now().month(), DateTime.now().day(), 0,0,0).addDays(1);
        
        // Verify the next time the job will run
        System.assertEquals(expectedNextFireTime, ct.NextFireTime);
    }
}