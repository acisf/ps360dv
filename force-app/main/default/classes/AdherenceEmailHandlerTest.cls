@isTest
private class AdherenceEmailHandlerTest {
    
    @testSetup
    static void setupData() {
        // Create a couple of Users to map against agent emails
        User u1 = new User(
            FirstName = 'Test',
            LastName = 'Agent',
            Email = 'agent1@example.com',
            FederationIdentifier = 'agent1@example.com',
            Username = 'agent1@example.com' + System.currentTimeMillis(),
            Alias = 'a1',
            CommunityNickname = 'a1nick',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u1;
    }
    
    @isTest
    static void testHandleInboundEmail_withValidCsv() {
        String csv = 'Agent,Agent Email,Date,Adherence (%),In Adherence Time (s),Neutral Adherence Time (s),Out of Adherence Time (s)\n' +
            'Agent One,agent1@example.com,08/23/2025 12:00 AM,95,300,50,25\n';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail.TextAttachment csvFile = new Messaging.InboundEmail.TextAttachment();
        csvFile.fileName = 'adherence.csv';
        csvFile.body = csv;
        email.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{csvFile};
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        AdherenceEmailHandler handler = new AdherenceEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();
        
        System.assert(result.success, 'Result should be success');
        
        // Verify record inserted
        List<Adherence__c> recs = [SELECT Id, employeeIdentifier__c, Calabrio_Shift_Date__c, Agent__c FROM Adherence__c];
        System.assertEquals(1, recs.size(), 'One adherence record should have been upserted');
        System.assertEquals('agent1@example.com', recs[0].employeeIdentifier__c);
        System.assertNotEquals(null, recs[0].Agent__c, 'Agent should be mapped');
    }
    
    @isTest
    static void testHandleInboundEmail_noAttachment() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.textAttachments = new List<Messaging.InboundEmail.TextAttachment>(); // empty
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        AdherenceEmailHandler handler = new AdherenceEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        
        System.assert(result.success, 'Should succeed even with no attachment');
    }
    
    @isTest
    static void testHandleInboundEmail_nonCsvAttachment() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail.TextAttachment txtFile = new Messaging.InboundEmail.TextAttachment();
        txtFile.fileName = 'notes.txt';
        txtFile.body = 'random stuff';
        email.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{txtFile};
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        AdherenceEmailHandler handler = new AdherenceEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        
        System.assert(result.success, 'Should succeed but do nothing');
        System.assertEquals(0, [SELECT count() FROM Adherence__c], 'No records should be inserted');
    }
    
    @isTest
    static void testProcessCsvRow_validRow() {
        String row = 'Agent One,agent1@example.com,08/23/2025 12:00 AM,95,300,50,25';
        Adherence__c rec = AdherenceEmailHandler.processCsvRow(row);
        
        System.assertNotEquals(null, rec, 'Row should be parsed into a record');
        System.assertEquals('agent1@example.com', rec.Calabrio_Person_Email__c);
        System.assertEquals(Date.newInstance(2025,8,23), rec.Calabrio_Shift_Date__c);
        System.assertEquals(Decimal.valueOf(300), rec.Calabrio_In_Adherence_Time__c);
    }
    
    @isTest
    static void testProcessCsvRow_blankRow() {
        Adherence__c rec = AdherenceEmailHandler.processCsvRow('');
        System.assertEquals(null, rec, 'Blank row should return null');
    }
    
    @isTest
    static void testParseDate_valid() {
        Date d = AdherenceEmailHandler.parseDate('08/23/2025 12:00 AM');
        System.assertEquals(Date.newInstance(2025, 8, 23), d);
    }
    
    @isTest
    static void testParseDate_invalid() {
        Date d = AdherenceEmailHandler.parseDate('bad-date');
        System.assertEquals(null, d, 'Invalid date string should return null');
    }
    
    @isTest
    static void testTryParseDecimal() {
        System.assertEquals(Decimal.valueOf(10), AdherenceEmailHandler.tryParseDecimal('10'));
        System.assertEquals(null, AdherenceEmailHandler.tryParseDecimal('abc'));
        System.assertEquals(null, AdherenceEmailHandler.tryParseDecimal(''));
    }
    
    @isTest
    static void testParseCsvLine_withQuotes() {
        String row = '"Agent, Sr","agent2@example.com","08/24/2025 12:00 AM","95","300","50","25"';
        List<String> fields = AdherenceEmailHandler.parseCsvLine(row);
        System.assertEquals(7, fields.size(), 'Should parse 7 fields correctly');
        System.assertEquals('Agent, Sr', fields[0], 'Quoted field should retain comma inside');
    }
}