@isTest
private class TxtReplyHandlerTest {
    @isTest
    static void testHandleInboundEmail() {
        // Create a test account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Location_Id__c = '01001'; 
        insert testAccount;
        
        // Create a test inbound email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Subject';
        email.plainTextBody = 'FirstName::John\nLastName::Doe\nPhoneNumber::1234567890\nLocationId::01001'; 
        email.htmlBody = '<html><body>FirstName::John<br/>LastName::Doe<br/>PhoneNumber::1234567890<br/>LocationId::01001</body></html>'; // Include LocationId line
        
        // Create a test inbound envelope
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        Test.startTest();
        
        // Call the handleInboundEmail method
        TxtReplyHandler handler = new TxtReplyHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        handler.sendErrorEmail('test','test');
        Test.stopTest();
        
        // Verify that the result is successful
        System.assert(result.success, 'Expected handleInboundEmail to be successful');
        
        // Verify that a Case was created
        List<Case> cases = [SELECT Id, AccountId FROM Case];
        System.assertEquals(1, cases.size(), 'Expected one Case to be created');
        
        // Verify that the Case is associated with the correct Account
        Case createdCase = cases[0];
        System.assertEquals(testAccount.Id, createdCase.AccountId, 'Expected Case to be associated with the correct Account');
    }
}