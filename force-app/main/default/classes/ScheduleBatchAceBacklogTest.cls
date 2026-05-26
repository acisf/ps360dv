@isTest
public class ScheduleBatchAceBacklogTest {
    static testmethod void test() {
        String jobId = System.schedule('Test_ACE_Backlog', '0 0 0 3 9 ? 2099', new ScheduleBatchAceBacklog());
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        System.assertEquals( '0 0 0 3 9 ? 2099', ct.CronExpression);
        
        System.assertEquals('2099-09-03 00:00:00', 
                            String.valueOf(ct.NextFireTime));
    }
}