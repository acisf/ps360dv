@isTest
public class ScheduleBatchTrustPilotEmailTest {
    
    static testmethod void test() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,  new Mocktopus(Mocktopus.MockScenario.GENERIC));         
        // Schedule the test job
        String jobId = System.schedule('Practice Review Email Test','0 0 13 1/1 * ? *',new ScheduleBatchTrustPilotEmail());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals( '0 0 13 1/1 * ? *', ct.CronExpression);
        System.assertNotEquals( null, ct.NextFireTime);
        Test.stopTest();
    }
}