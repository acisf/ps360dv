@isTest
public class BatchDeleteUnusedContactsTest  {

    @isTest
    public static void testDeletionOfUnusedCont(){
        Id patientRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
        List<Contact> lstCon = new List<Contact>();
        DateTime dt = DateTime.now().AddDays(-40);
        Account acc = new Account(name='Test Practice');
        insert acc;     
        
        FB_Lead__c fbLead = new FB_Lead__c();
        fbLead.FB_Practice__c = acc.Id;
        fbLead.FB_First_Name__c = 'Test2';
        fbLead.FB_Last_Name__c = 'Contact2';
        fbLead.FB_Scheduled_1__c = Date.Today();
        insert fbLead;        
        
        Contact c1 = new Contact();
        c1.AccountId = acc.Id;
        c1.RecordTypeId = patientRT;
        c1.FirstName = 'Test1';
        c1.LastName = 'Contact1';
        c1.Email = 'Test1.Contact1@example.com';
        c1.Description = 'Practice Review email';        
        lstCon.add(c1);
        
        Contact c2 = new Contact();
        c2.AccountId = acc.Id;
        c2.RecordTypeId = patientRT;
        c2.FirstName = 'Test2';
        c2.LastName = 'Contact2';
        c2.Email = 'Test2.Contact2@example.com';       
        c2.FB_Lead_Id__c = fbLead.Id;        
        lstCon.add(c2);
        
        Contact c3 = new Contact();
        c3.AccountId = acc.Id;
        c3.RecordTypeId = patientRT;
        c3.FirstName = 'Test3';
        c3.LastName = 'Contact3';
        c3.Email = 'Test3.Contact3@example.com';
        c3.Description = 'Practice Review email';        
        lstCon.add(c3);
        
        Contact c4 = new Contact();
        c4.AccountId = acc.Id;
        c4.RecordTypeId = patientRT;
        c4.FirstName = 'Test4';
        c4.LastName = 'Contact4';
        c4.Email = 'Test4.Contact4@example.com';         
        c4.FB_Lead_Id__c = fbLead.Id;        
        lstCon.add(c4);
        
        Contact c5 = new Contact();
        c5.AccountId = acc.Id;
        c5.RecordTypeId = patientRT;
        c5.FirstName = 'Test5';
        c5.LastName = 'Contact5';
        c5.Email = 'Test5.Contact5@example.com';
        c5.Description = 'Practice Review email';        
        lstCon.add(c5);
        
        Contact c6 = new Contact();
        c6.AccountId = acc.Id;
        c6.RecordTypeId = patientRT;
        c6.FirstName = 'Test6';
        c6.LastName = 'Contact6';
        c6.Email = 'Test6.Contact6@example.com';
        c6.Description = 'Practice Review email';        
        lstCon.add(c6);
        
        insert lstCon;
        Test.setCreatedDate(c1.id, dt);
        Test.setCreatedDate(c2.id, dt);
        Test.setCreatedDate(c3.id, dt);
        Test.setCreatedDate(c4.id, dt);
        Test.setCreatedDate(c5.id, dt);
        
        Task t1 = new Task();
        t1.Subject = 'Inbound call from 9199999999';
        t1.Priority = 'Normal';
        t1.Status = 'Completed';
        t1.WhoId = c1.id;
        insert t1;
        
        Task t2 = new Task();
        t2.Subject = 'Inbound call from 9199998888';
        t2.Priority = 'Normal';
        t2.Status = 'Completed';
        t2.WhoId = c2.id;
        insert t2;
        
        Case c = new Case();
        c.AccountId = acc.id;
        c.ContactId = c3.Id;
        c.Subject = 'Test case 1';
        c.Description = 'Test case 1';
        insert c;
                
        List<Contact> contacts = [Select id from contact where recordtypeid = :patientRT];
        System.assertEquals(6, contacts.size());
        
        Test.startTest();
        BatchDeleteUnusedContacts bdc = new BatchDeleteUnusedContacts();
        Database.executeBatch(bdc);
        Test.stopTest();
        
        contacts = [Select id from contact where recordtypeid = :patientRT];
        System.assertEquals(4, contacts.size());
    }
}