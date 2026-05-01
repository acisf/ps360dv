@isTest
private class TreatmentFinderLeadNotifierTest {

    @isTest
    static void runTest() {

        // 1. Create Account (Practice)
        Account acc = new Account(
            Name = 'Fort Worth',
            Location_Id__c = '15210'
        );
        insert acc;

        // 2. Create Contact (Recipient)
        Contact c = new Contact(
            FirstName = 'Megan',
            LastName = 'Receiver',
            Email = 'megan.receiver@test.com',
            AccountId = acc.Id
        );
        insert c;

        // 3. Create Practice Contact Role
        Practice_Contact_Role__c role = new Practice_Contact_Role__c(
            Practice__c = acc.Id,
            Contact__c = c.Id,
            Role__c = 'Treatment Finder Lead Recipient'
        );
        insert role;

        // 4. Get Record Type for Treatment Finder
        Id rtId = Schema.SObjectType.Lead
            .getRecordTypeInfosByName()
            .get('Treatment Finder')
            .getRecordTypeId();

        // 5. Create Test JSON (based on your real structure)
        String tfJson = '{"quiz_result":[' +
            '{"question":"When are you ready to start your treatment?","answer":"1-2 months"},' +
            '{"question":"What type of dental insurance do you have?","answer":"Commercial insurance"},' +
            '{"question":"Do you currently wear dentures?","answer":["Loose fit","Can’t eat well"]}' +
            '],' +
            '"treatment_options":[' +
            '{"treatment_name":"Premium Dentures","pricing":{"monthly_range":{"min":74}}}' +
            ']}';

        // 6. Create Lead
        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Patient',
            Email = 'test.patient@example.com',
            Company = 'Test Company',
            Location_Id__c = '15210',
            RecordTypeId = rtId,
            TF_JSON__c = tfJson,
            Lead_Notification_Sent_Date__c = null
        );
        insert l;

        // 7. Execute
        Test.startTest();
        TreatmentFinderLeadNotifier.sendNotifications();
        Test.stopTest();

        // 8. Verify Lead Updated
        Lead updatedLead = [
            SELECT Lead_Notification_Sent_Date__c
            FROM Lead
            WHERE Id = :l.Id
        ];

        System.assertNotEquals(
            null,
            updatedLead.Lead_Notification_Sent_Date__c,
            'Lead should have notification date set'
        );

        System.assertEquals(
            Date.today(),
            updatedLead.Lead_Notification_Sent_Date__c,
            'Notification date should be today'
        );
    }
}