@isTest
public class ScheduleOutboundBatchTest {
    @isTest
    static void testScheduleBatchStarter() {
        String cronExp = '0 0 22 1 7 ? 2099'; 

        Test.startTest();
        String jobId = System.schedule('Test - Run TmpBatchProcess', cronExp, new ScheduleOutboundBatch());
        Test.stopTest();

        // Verify the job is scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger
                          WHERE Id = :jobId];

        System.assertEquals('0 0 22 1 7 ? 2099', ct.CronExpression);
        System.assertNotEquals(null, ct.NextFireTime);
    }
}