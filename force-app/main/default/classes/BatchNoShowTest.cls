@IsTest
private class BatchNoShowTest {
    
    @TestSetup
    static void setupData() {
        // Create an Account with Location_Id__c (practice)
        Account acct = new Account(
            Name = 'Test Location',
            Location_Id__c = '12345'
        );
        insert acct;
        
        // Create a Zeta_User (new patient)
        Zeta_User__c zUser = new Zeta_User__c(
            user_id__c = 'user-001',
            first_name__c = 'John',
            last_name__c = 'Doe',
            email__c = 'john@example.com',
            phone_appointment__c = '9191231234',
            practice_id__c = '12345'
        );
        insert zUser;
        
        // Related Zeta_Event (no_show)
        Zeta_Event__c zEvent = new Zeta_Event__c(
            user_id__c = zUser.user_id__c,
            event_type__c = 'no_show'
        );
        insert zEvent;
    }
    
    @IsTest
    static void testBatchCreatesContactAndCase() {
        // Get today's date for constructor
        Date today = Date.today();
        
        Test.startTest();
        Database.executeBatch(new BatchNoShow(today), 50);
        Test.stopTest();
        
        // Assert Contact created
        Contact c = [
            SELECT Id, FirstName, LastName, Email, MobilePhone, Account.Location_Id__c
            FROM Contact
            WHERE LastName = 'Doe'
            LIMIT 1
        ];
        System.assertEquals('John', c.FirstName, 'Contact first name should be capitalized');
        System.assertEquals('Doe', c.LastName);
        System.assertEquals('john@example.com', c.Email);
        System.assertEquals('9191231234', c.MobilePhone);
        System.assertEquals('12345', c.Account.Location_Id__c);
        
        // Assert Case created
        Case createdCase = [
            SELECT Id, Subject, Status, Offer__c, ContactId, AccountId, Description
            FROM Case
            WHERE ContactId = :c.Id
            LIMIT 1
        ];
        System.assertEquals('New', createdCase.Status);
        System.assertEquals('Appt No Show', createdCase.Offer__c);
        System.assert(createdCase.Subject.contains('12345'),
            'Case subject should include Location Id');
        System.assert(createdCase.Description.contains('First: John'),
            'Case description should include first name');
    }
    
    @IsTest
    static void testSanitizeZetaUserAndGenerateContactKey() {
        Zeta_User__c zUser = new Zeta_User__c(
            first_name__c = ' Alice ',
            last_name__c = ' Smith ',
            phone_appointment__c = '1-800-555-1212',
            practice_id__c = '9999'
        );
        
        BatchNoShow batch = new BatchNoShow(Date.today());
        
        // Call sanitize
        Test.startTest();
        batch.sanitizeZetaUser(zUser);
        Test.stopTest();
        
        System.assertEquals('alice', zUser.first_name__c, 'First name should be trimmed/lowercase');
        System.assertEquals('smith', zUser.last_name__c, 'Last name should be trimmed/lowercase');
        System.assertEquals('8005551212', zUser.phone_appointment__c,'Phone should be sanitized to last 10 digits');
        System.assertEquals('09999', zUser.practice_id__c);
        
        // Call generateContactKey
        String key = batch.generateContactKey(zUser);
        System.assert(key.contains('alice-smith'), 'Key should include sanitized names');
        System.assert(key.contains('8005551212'), 'Key should include phone');
        System.assert(key.endsWith('09999'), 'Key should include practice id');
    }
    
    @IsTest
    static void testMapZetaUserToContact() {
        // Need a practice Account
        Account acct = [SELECT Id, Location_Id__c FROM Account LIMIT 1];
        
        Zeta_User__c zUser = new Zeta_User__c(
            user_id__c = 'user-002',
            first_name__c = 'bob',
            last_name__c = 'jones',
            email__c = 'bob@example.com',
            phone_appointment__c = '222-333-4444',
            practice_id__c = acct.Location_Id__c
        );
        
        BatchNoShow batch = new BatchNoShow(Date.today());
        Map<String, Id> practiceMap = new Map<String, Id>{acct.Location_Id__c => acct.Id};
        Contact c = batch.mapZetaUserToContact(zUser, 'dummyKey', practiceMap);
        
        System.assertEquals('Bob', c.FirstName, 'First name should be capitalized');
        System.assertEquals('Jones', c.LastName);
        System.assertEquals('bob@example.com', c.Email);
        System.assertEquals('2223334444'.substring(0,10), c.MobilePhone.replaceAll('[^0-9]', ''));
        System.assertEquals(acct.Id, c.AccountId, 'Contact should map to practice account');
    }
}