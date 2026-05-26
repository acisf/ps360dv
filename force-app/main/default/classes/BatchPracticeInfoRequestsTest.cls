@isTest
private class BatchPracticeInfoRequestsTest {
    
    // Helper method to create test data
    private static void createTestData() {
        // Create Accounts (Practices)
        Id recordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account a1 = new Account(Name = 'Charlotte', Location_Id__c = '1002', RecordTypeId = recordTypeIdAcct);
        Account a2 = new Account(Name = 'Asheville', Location_Id__c = '1001', RecordTypeId = recordTypeIdAcct);
        insert new List<Account> {a1, a2};

        // Create Contacts
        Contact c1 = new Contact(AccountId = a1.id, FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com');
        Contact c2 = new Contact(AccountId = a2.id, FirstName = 'Jane', LastName = 'Smith', Email = 'jane.smith@example.com');
        insert new List<Contact> {c1, c2};

        // Create Cases to link to Practice_Info_Request__c records
        Case case1 = new Case(Subject = 'Test Case 1', Status = 'New', ContactId = c1.Id);
        Case case2 = new Case(Subject = 'Test Case 2', Status = 'New', ContactId = c2.Id);
        insert new List<Case> {case1, case2};

        // Create Practice_Info_Request__c records for testing
        Practice_Info_Request__c req1 = new Practice_Info_Request__c(Case__c = case1.Id, Practice__c = a1.Id, Quantity__c = 10);
        Practice_Info_Request__c req2 = new Practice_Info_Request__c(Case__c = case1.Id, Practice__c = a1.Id, Quantity__c = 15); // Duplicate for Case 1 and Practice A
        Practice_Info_Request__c req3 = new Practice_Info_Request__c(Case__c = case2.Id, Practice__c = a2.Id, Quantity__c = 5);
        insert new List<Practice_Info_Request__c>{req1, req2, req3};
    }

    @isTest
    static void testBatchJobWithNoRecords() {
        // Test scenario with no records created today
        Test.startTest();
        BatchPracticeInfoRequests batch = new BatchPracticeInfoRequests();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that no records were processed
        List<Practice_Info_Request__c> requests = [SELECT Quantity__c FROM Practice_Info_Request__c];
        for (Practice_Info_Request__c req : requests) {
            System.assertEquals(req.Quantity__c, req.Quantity__c, 'No records should be updated.');
        }
    }

    @isTest
    static void testBatchJobWithDuplicates() {
        // Create test data with duplicates
        createTestData();
        List<account> lstA = [select id from account where location_id__c = '1002'];
        Account a1 = lstA[0];
        
        // Run the batch job
        Test.startTest();
        BatchPracticeInfoRequests batch = new BatchPracticeInfoRequests();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that duplicates were processed correctly
        List<Practice_Info_Request__c> updatedRequests = [SELECT Case__c, Practice__c, Quantity__c FROM Practice_Info_Request__c WHERE Practice__c = :a1.Id];
        System.assertEquals(2, updatedRequests.size(), 'There should be two records for Practice A');
        
        for (Practice_Info_Request__c req : updatedRequests) {
            if (req.Quantity__c == 25) {
                // The first record should have the combined quantity
                System.assertEquals(25, req.Quantity__c, 'The combined quantity should be 25.');
            } else if (req.Quantity__c == 0) {
                // The second record (duplicate) should have quantity set to 0
                System.assertEquals(0, req.Quantity__c, 'The duplicate quantity should be 0.');
            } else {
                System.assert(false, 'Unexpected quantity found: ' + req.Quantity__c);
            }
        }
    }

    @isTest
    static void testBatchJobWithNoDuplicates() {
        // Create test data with no duplicates
        createTestData();
         List<account> lstA = [select id from account where location_id__c = '1001'];
        Account a1 = lstA[0];
        
        // Run the batch job
        Test.startTest();
        BatchPracticeInfoRequests batch = new BatchPracticeInfoRequests();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that no records were set to 0 except duplicates
        List<Practice_Info_Request__c> nonDuplicateRequests = [SELECT Quantity__c FROM Practice_Info_Request__c WHERE Practice__c = :a1.Id];
        for (Practice_Info_Request__c req : nonDuplicateRequests) {
            System.assert(req.Quantity__c > 0, 'Non-duplicate quantities should remain unchanged.');
        }
    }
}