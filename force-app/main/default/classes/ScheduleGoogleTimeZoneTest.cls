@istest
class ScheduleGoogleTimeZoneTest {
    static testmethod void test() {
        Test.startTest();
        
        // Schedule the test job
        String jobId = System.schedule('test_cna_job', '0 0 0 3 12 ? 2025', new ScheduleGoogleTimeZone());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals( '0 0 0 3 12 ? 2025', ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        System.assertEquals('2025-12-03 00:00:00', 
                            String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
}