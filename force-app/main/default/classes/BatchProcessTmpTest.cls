@isTest
public class BatchProcessTmpTest {
    @testSetup
    static void setup() {
        // Create Accounts
        Account account1 = new Account(Name = 'Account 1', Location_Id__c = '00001');
        Account account2 = new Account(Name = 'Account 2', Location_Id__c = '00002');
         Account account3 = new Account(Name = 'Account 3', Location_Id__c = '00003');
        insert new List<Account>{ account1, account2, account3 };
        
        // Create Contacts
        Contact contact1 = new Contact(FirstName = 'John', LastName = 'Doe', MobilePhone = '1234567890', AccountId = account1.Id, RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId());
        Contact contact2 = new Contact(FirstName = 'Jane', LastName = 'Smith', MobilePhone = '0987654321', AccountId = account2.Id, RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId());
        insert new List<Contact>{ contact1, contact2 };
        
        // Create tmp__c records
        tmp__c tmpRecord1 = new tmp__c(first__c = 'John', last__c = 'Doe', locationid__c = '1', phone__c = '(123) 456-7890', Offer__c = 'Special Offer');
        tmp__c tmpRecord2 = new tmp__c(first__c = 'Jane', last__c = 'Smith', locationid__c = '2', phone__c = '098-765-4321', Offer__c = 'Special Offer 2');
        tmp__c tmpRecord3 = new tmp__c(first__c = 'Mike', last__c = 'Johnson', locationid__c = '3', phone__c = '+1(111) 222-3333', Offer__c = 'Special Offer 3');
        insert new List<tmp__c>{ tmpRecord1, tmpRecord2, tmpRecord3 };
    }
    
    @isTest
    static void testBatchProcess() {
        // Verify initial state
        List<tmp__c> tmpRecords = [SELECT Id, contact__c, first__c, last__c, locationid__c, phone__c, practice__c, Offer__c FROM tmp__c];
        System.assertEquals(3, tmpRecords.size());
        for (tmp__c tmp : tmpRecords) {
            System.assertEquals(null, tmp.contact__c);
            System.assertEquals(null, tmp.practice__c);
        }
        
        // Execute the batch
        Test.startTest();
        BatchProcessTmp batch = new BatchProcessTmp();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the results
        tmpRecords = [SELECT Id, contact__c, first__c, last__c, locationid__c, phone__c, practice__c, Offer__c FROM tmp__c];
        
        for (tmp__c tmp : tmpRecords) {
            if (tmp.first__c == 'John' && tmp.last__c == 'Doe') {
                System.assertNotEquals(null, tmp.contact__c);
                System.assertNotEquals(null, tmp.practice__c);
            } else if (tmp.first__c == 'Jane' && tmp.last__c == 'Smith') {
                System.assertNotEquals(null, tmp.contact__c);
                System.assertNotEquals(null, tmp.practice__c);
            } else if (tmp.first__c == 'Mike' && tmp.last__c == 'Johnson') {
                System.assertNotEquals(null, tmp.practice__c);
                System.assertNotEquals(null, tmp.contact__c);
            }
        }
    }
}