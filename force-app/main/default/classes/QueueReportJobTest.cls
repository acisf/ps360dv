@isTest(SeeAllData=true)
public class QueueReportJobTest {
    @isTest
    static void testQueueReportJob_withRealQueue() {
        // Look for a real test queue created in setup
        Group testQueue = [
            SELECT Id, Name 
            FROM Group 
            WHERE Type = 'Queue' 
              AND Name = 'Test Queue' 
            LIMIT 1
        ];

        // Ensure it has at least one user member
        List<GroupMember> members = [
            SELECT UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId = :testQueue.Id
        ];

        System.assert(!members.isEmpty(), 'Test Queue must have at least one member');

        Test.startTest();
        QueueReportJob.runQueueReport();
        Test.stopTest();

        // Validate the inserted Queue_Report__c record(s)
        List<Queue_Report__c> reports = [
            SELECT Id, Queue_Name__c, User__c 
            FROM Queue_Report__c 
            WHERE Queue_Id__c = :testQueue.Id
        ];

        System.assert(!reports.isEmpty(), 'Expected at least one report entry for Test Queue');
        System.assertEquals('Test Queue', reports[0].Queue_Name__c);
    }
}