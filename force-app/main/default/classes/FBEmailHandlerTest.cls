@isTest
public class FBEmailHandlerTest {
    
    @isTest
    static void testHandleInboundEmail() {
        // Create a test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Location_id__c = '10233'
        );
        insert testAccount;
        
        // Create a dummy email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Subject';
        email.plainTextBody = '===================\nPATIENT INFORMATION\n===================\nFirst Name:: Glenn\nLast Name:: Allen\nPhone:: 5132558816\nEmail:: kelgia12@gmail.com\nLocation:: 10233\nCreated:: 07/12/2024 04:46 AM EDT\nLead Rating:: HOT\n';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        // Instantiate the handler
        FBEmailHandler handler = new FBEmailHandler();
        
        // Call the handler
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        // Verify results
        System.assert(result.success, 'The email processing should be successful.');
        
        // Verify the contact was created
        Contact contact = [SELECT Id, FirstName, LastName, MobilePhone, Email, AccountId, RecordTypeId FROM Contact WHERE MobilePhone = '5132558816' LIMIT 1];
        System.assertEquals('Glenn', contact.FirstName);
        System.assertEquals('Allen', contact.LastName);
        System.assertEquals(Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId(), contact.RecordTypeId);
        
        // Verify the case was created
        Case newCase = [SELECT Id, Subject, ContactId, AccountId, Description, Status, RecordTypeId, OwnerId, Offer__c FROM Case WHERE ContactId = :contact.Id LIMIT 1];
        System.assertEquals('Test Subject', newCase.Subject);
    }
}