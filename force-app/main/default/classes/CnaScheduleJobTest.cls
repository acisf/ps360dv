@IsTest
class CnaScheduleJobTest {
    static testmethod void test() {
        Test.startTest();
        
        // Get a date in the future for scheduling the job (e.g., one day from today)
        Date futureDate = Date.today().addDays(1);
        
        // Build a cron expression for a future date at midnight
        String cronExpression = '0 0 0 ' + futureDate.day() + ' ' + futureDate.month() + ' ? ' + futureDate.year();
        
        // Schedule the test job with a future date
        String jobId = System.schedule('test_CnaJob', cronExpression, new CnaScheduleJob());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals(cronExpression, ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run matches the future date
        System.assertEquals(futureDate, ct.NextFireTime.date());
        
        Test.stopTest();
    }
}