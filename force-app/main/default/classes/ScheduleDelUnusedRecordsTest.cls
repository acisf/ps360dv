@isTest
public class ScheduleDelUnusedRecordsTest {

    static testmethod void test() {
 		// Schedule the test job
        String jobId = System.schedule('Test_Schedule_Delete_Records', '0 0 0 3 9 ? 2099', new ScheduleDelUnusedRecords());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals( '0 0 0 3 9 ? 2099', ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        System.assertEquals('2099-09-03 00:00:00', 
                            String.valueOf(ct.NextFireTime));
    }

}