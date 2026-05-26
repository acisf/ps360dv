@isTest
private class BatchAceBacklogTest {

    @testSetup
    static void setupData() {
        // Query the existing 'ACE Service' RecordType for Case
        RecordType aceRt = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Case' AND DeveloperName = 'ACE_Service'
            LIMIT 1
        ];

        // Create some open Cases with that RecordType
        List<Case> cases = new List<Case>();

        for (Integer i = 0; i < 5; i++) {
            cases.add(new Case(
                RecordTypeId     = aceRt.Id,
                Status           = 'New',
                Subject          = 'Test Case ' + i,
                CreatedDate      = DateTime.now().addDays(-i),
                Team__c          = 'Team A',
                Category__c      = 'General',
                Subcategory__c   = 'Issue',
                Queue_Name__c    = 'Support Queue'
            ));
        }

        insert cases;
    }

    @isTest
    static void testBatchCreatesBacklogRecords() {
        Date testBacklogDate = Date.newInstance(2025, 8, 1);

        Test.startTest();
        Database.executeBatch(new BatchAceBacklog(testBacklogDate), 50);
        Test.stopTest();

        List<ACE_Backlog__c> backlogs = [
            SELECT Case__c, Case_Number__c, Team__c, Category__c,
                   Subcategory__c, Queue_Name__c, DateTime_Opened__c,
                   Age__c, Backlog_Date__c
            FROM ACE_Backlog__c
        ];

        System.assertEquals(5, backlogs.size(), 'Expected 5 ACE_Backlog__c records.');

        for (ACE_Backlog__c bl : backlogs) {
            System.assertEquals(testBacklogDate, bl.Backlog_Date__c, 'Backlog date mismatch');
            System.assertNotEquals(null, bl.Age__c, 'Age__c should not be null');
            System.assertNotEquals(null, bl.Case__c, 'Case__c should not be null');
            System.assertNotEquals(null, bl.Case_Number__c, 'Case_Number__c should not be null');
        }
    }
}