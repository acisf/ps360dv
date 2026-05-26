@isTest
public class CaseOwnerControllerTest {

    @isTest
    static void testInvokeAssignmentRules() {
        // Create a test case to use in the test
        Case testCase = new Case(
            Subject = 'Test Case for Assignment Rule',
            Status = 'New'
        );
        insert testCase;

        // Call the invocable method
        Test.startTest();
        CaseOwnerController.invokeAssignmentRules(testCase.Id);
        Test.stopTest();

        // Retrieve the case again to verify if the assignment rule was applied
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];

        // Assert that the assignment rule has changed the owner
        System.assertNotEquals(testCase.OwnerId, updatedCase.OwnerId, 'The case owner should have been updated by the assignment rule.');
    }

    @isTest
    public static void testSendUserOwnerNotification() {
        
       Id currentUserId = UserInfo.getUserId();
        String emailAddress =   UserInfo.getUserEmail();

        Id aceId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'ACE_Service' LIMIT 1].Id;

        // Create a case with the user as the owner
        Case caseRecord = new Case(
            Subject = 'Test Case for User Owner Notification',
            Status = 'New',
            RecordTypeId = aceId,
            OwnerId = currentUserId
        );
        insert caseRecord;
        
        System.debug(caseRecord.ownerid);
        // Invoke the method and verify email sending
        Test.startTest();
        CaseOwnerController.sendOwnerNotification(caseRecord.Id);
        Test.stopTest();

        Integer invocations = Limits.getEmailInvocations();
        System.assertEquals(1, invocations, 'An email should be sent to the user.');
    }

    @isTest
    public static void testSendQueueOwnerNotification() {
        // Query for the "IT: Service Desk" queue
        Group itServiceDeskQueue = [SELECT Id, DeveloperName, Type FROM Group WHERE DeveloperName = 'Service_Desk' AND Type = 'Queue' LIMIT 1];
        System.assertNotEquals(itServiceDeskQueue, null, 'The "IT: Service Desk" queue does not exist.');

        // Query for users in the queue
        List<User> queueUsers = [
            SELECT Id, Email
            FROM User
            WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :itServiceDeskQueue.Id)
        ];
        System.assert(queueUsers.size() > 0, 'The "IT: Service Desk" queue should have at least one user.');

        // Create a case with the queue as the owner
        Case caseRecord = new Case(
            Subject = 'Test Case for Queue Notification',
            Status = 'New',
            OwnerId = itServiceDeskQueue.Id
        );
        insert caseRecord;

        // Invoke the method
        Test.startTest();
        CaseOwnerController.sendOwnerNotification(caseRecord.Id);
        Test.stopTest();

        Integer invocations = Limits.getEmailInvocations();
        System.assertEquals(1, invocations, 'An email should be sent to all queue members.');
    }

   

    @isTest
    public static void testGetQueuesByDepartment() {
        // Set up test data
        String departmentName = 'IT';

        Queue__c queue1 = new Queue__c(Name = 'IT Queue 1', Queue_Id__c = 'Q1', department__c = departmentName);
        Queue__c queue2 = new Queue__c(Name = 'IT Queue 2', Queue_Id__c = 'Q2', department__c = departmentName);
        Queue__c queue3 = new Queue__c(Name = 'HR Queue', Queue_Id__c = 'Q3', department__c = 'HR');
        insert new List<Queue__c> { queue1, queue2, queue3 };

        // Call the method and verify results
        Test.startTest();
        List<Queue__c> queues = CaseOwnerController.getQueuesByDepartment(departmentName);
        Test.stopTest();

        // Assert the results
        System.assertEquals(2, queues.size(), 'Should return 2 queues for the IT department');
    }

    @isTest
    public static void testGetUsersByDepartment() {
        // Set up test data
        String departmentName = 'Acct';
        // Call the method and verify results
        Test.startTest();
        List<User> users = CaseOwnerController.getUsersByDepartment(departmentName);
        Test.stopTest();

        // Assert the results
        System.assertEquals(0, users.size(), 'Should return 0 users for the Acct department');
    }
}