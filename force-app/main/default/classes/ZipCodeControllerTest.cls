@isTest
public class ZipCodeControllerTest {
    @testSetup
    static void setupTestData() {
        // Get the Record Type Id for 'Schedule Assist'
        Id scheduleAssistRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Schedule Assist' AND SObjectType = 'Account' LIMIT 1].Id;
        
        // Create test accounts with geolocation
        Account acc1 = new Account(Name = 'Test Account 1', RecordTypeId = scheduleAssistRecordTypeId, BillingLatitude = 35.7796, BillingLongitude = -78.6382, IsClosed__c = false);
        Account acc2 = new Account(Name = 'Test Account 2', RecordTypeId = scheduleAssistRecordTypeId, BillingLatitude = 35.7746, BillingLongitude = -78.6322, IsClosed__c = false);
        Account acc3 = new Account(Name = 'Test Account 3', RecordTypeId = scheduleAssistRecordTypeId, BillingLatitude = 35.7700, BillingLongitude = -78.6300, IsClosed__c = false);
        insert new List<Account>{acc1, acc2, acc3};
    }
    
    @isTest
    static void testCalcNearestAccounts() {
        // Create a test Zip_Code__c record
        Zip_Code__c testZip = new Zip_Code__c(Name = '27601', Latitude__c = 35.7780, Longitude__c = -78.6390);
        insert testZip;
        
        // Call the method under test
        Test.startTest();
        testZip = new ZipCodeController().calcNearestAccounts(testZip);
        Test.stopTest();
        
        // Verify that the nearest accounts are assigned correctly
        System.assertNotEquals(null, testZip.Practice_1__c, 'Practice_1__c should be assigned.');
        System.assertNotEquals(null, testZip.Practice_2__c, 'Practice_2__c should be assigned.');
        System.assertNotEquals(null, testZip.Practice_3__c, 'Practice_3__c should be assigned.');
    }
}