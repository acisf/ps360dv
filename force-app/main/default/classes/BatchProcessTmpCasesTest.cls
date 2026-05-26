@isTest
public class BatchProcessTmpCasesTest {
    @testSetup
    static void setup() {
        // Query the RecordType for Case
        RecordType outboundCampaignRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Outbound_Campaign' LIMIT 1];
        
        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Location_Id__c = '12345'
        );
        insert testAccount;
        
        // Create a test Contact with the 'Patient' record type
        RecordType patientRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'Patient' LIMIT 1];
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            MobilePhone = '1234567890',
            RecordTypeId = patientRt.Id
        );
        insert testContact;
        
        // Create test tmp__c records
        tmp__c tmpRecord1 = new tmp__c(
            first__c = 'Test',
            last__c = 'Contact',
            locationid__c = '12345',
            phone__c = '1234567890',
            practice__c = testAccount.Id,
            contact__c = testContact.Id,
            Offer__c = 'Special Offer',
            Case_Created__c = false
        );
        insert tmpRecord1;
    }
    
    @isTest
    static void testBatchProcessing() {
        // Execute the batch
        Test.startTest();
        BatchProcessTmpCases batch = new BatchProcessTmpCases();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that a Case was created
        List<Case> cases = [SELECT Id, Subject, Offer__c, ContactId, AccountId, SuppliedPhone, Origin, Description FROM Case];
        System.assertEquals(1, cases.size(), 'One case should have been created.');
        Case newCase = cases[0];
        System.assertEquals('Special Offer', newCase.Offer__c, 'Offer should match.');
        System.assertEquals('1234567890', newCase.SuppliedPhone, 'Case supplied phone should match.');
        System.assertEquals('Campaign', newCase.Origin, 'Case origin should be Campaign.');
        
        // Verify the tmp__c record is updated
        List<tmp__c> tmpRecords = [SELECT Id, Case_Created__c FROM tmp__c];
        System.assertEquals(1, tmpRecords.size(), 'One tmp__c record should exist.');
        System.assertEquals(true, tmpRecords[0].Case_Created__c, 'tmp__c record should be marked as Case_Created__c = true.');
    }
}