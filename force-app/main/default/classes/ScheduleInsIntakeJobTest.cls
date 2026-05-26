@isTest
public class ScheduleInsIntakeJobTest {
    
    static testmethod void test() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.GENERIC));          
        // Schedule the test job
        String jobId = System.schedule('Afternoon','0 45 21 1/1 * ? *',new ScheduleInsIntakeJob());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals( '0 45 21 1/1 * ? *', ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        DateTime dt;
        dt = DateTime.newInstance(Date.today(),Time.newInstance(21,45,0,0));

        System.assertEquals( dt, ct.NextFireTime);
        Test.stopTest();
    }
}