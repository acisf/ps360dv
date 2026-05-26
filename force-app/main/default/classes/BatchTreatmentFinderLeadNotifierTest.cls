@isTest
private class BatchTreatmentFinderLeadNotifierTest {

    @testSetup
    static void setupData() {

        // 1. Create Account (Practice) — must use a pilot location ID
        Account acc = new Account(
            Name = 'Test Practice',
            Location_Id__c = '11340'
        );
        insert acc;

        // 2. Create Contact (Practice Contact Role recipient)
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

        // 4. Get Treatment Finder Record Type
        Id rtId = Schema.SObjectType.Lead
            .getRecordTypeInfosByName()
            .get('Treatment Finder')
            .getRecordTypeId();

        // 5. Test JSON — WARM lead (1-2 months), no appointment
        String tfJson = '{"quiz_result":[' +
            '{"question":"When are you ready to start your treatment?","answer":"1-2 months"},' +
            '{"question":"What type of dental insurance do you have?","answer":"Commercial insurance"},' +
            '{"question":"Do you currently wear dentures?","answer":["Loose fit","Can\'t eat well"]}' +
            '],' +
            '"treatment_options":[' +
            '{"treatment_name":"Premium Dentures","pricing":{"monthly_range":{"min":74}}}' +
            ']}';

        // 6. Lead that SHOULD be processed — pilot location, no appt, no prior notification
        Lead qualifiedLead = new Lead(
            FirstName = 'Test',
            LastName = 'Patient',
            Email = 'test.patient@example.com',
            Phone = '555-123-4567',
            Company = 'Test Company',
            Location_Id__c = '11340',
            RecordTypeId = rtId,
            TF_JSON__c = tfJson,
            Lead_Notification_Sent_Date__c = null,
            First_Appt_Date__c = null,
            CreatedDate= DateTime.now() - 1
        );

        // 7. Lead that should be EXCLUDED — has an appointment date
        Lead scheduledLead = new Lead(
            FirstName = 'Scheduled',
            LastName = 'Patient',
            Email = 'scheduled.patient@example.com',
            Company = 'Test Company',
            Location_Id__c = '11340',
            RecordTypeId = rtId,
            TF_JSON__c = tfJson,
            Lead_Notification_Sent_Date__c = null,
            First_Appt_Date__c = Date.today(),
			CreatedDate= DateTime.now() - 1
        );

        // 8. Lead that should be EXCLUDED — not a pilot location
        Lead nonPilotLead = new Lead(
            FirstName = 'NonPilot',
            LastName = 'Patient',
            Email = 'nonpilot.patient@example.com',
            Company = 'Test Company',
            Location_Id__c = '99999',
            RecordTypeId = rtId,
            TF_JSON__c = tfJson,
            Lead_Notification_Sent_Date__c = null,
            First_Appt_Date__c = null,
			CreatedDate = DateTime.now() - 1
        );

        // 9. Lead that should be EXCLUDED — notification already sent
        Lead alreadyNotifiedLead = new Lead(
            FirstName = 'Already',
            LastName = 'Notified',
            Email = 'already.notified@example.com',
            Company = 'Test Company',
            Location_Id__c = '11340',
            RecordTypeId = rtId,
            TF_JSON__c = tfJson,
            Lead_Notification_Sent_Date__c = Date.today().addDays(-1),
            First_Appt_Date__c = null,
			CreatedDate= DateTime.now() - 1
        );

        insert new List<Lead>{ qualifiedLead, scheduledLead, nonPilotLead, alreadyNotifiedLead };
    }

    // ─── Test: batch executes and stamps qualified lead ──────────────────────────

    @isTest
    static void testBatchProcessesQualifiedLead() {

        Test.startTest();
        Database.executeBatch(new BatchTreatmentFinderLeadNotifier(), 50);
        Test.stopTest();

        // Qualified lead should have notification date stamped
        Lead qualifiedLead = [
            SELECT Lead_Notification_Sent_Date__c
            FROM Lead
            WHERE FirstName = 'Test' AND LastName = 'Patient'
            LIMIT 1
        ];

        System.assertEquals(
            Date.today(),
            qualifiedLead.Lead_Notification_Sent_Date__c,
            'Qualified lead should have Lead_Notification_Sent_Date__c set to today'
        );
    }

    // ─── Test: leads with appointments are excluded ───────────────────────────────

    @isTest
    static void testScheduledLeadExcluded() {

        Test.startTest();
        Database.executeBatch(new BatchTreatmentFinderLeadNotifier(), 50);
        Test.stopTest();

        Lead scheduledLead = [
            SELECT Lead_Notification_Sent_Date__c
            FROM Lead
            WHERE FirstName = 'Scheduled' AND LastName = 'Patient'
            LIMIT 1
        ];

        System.assertEquals(
            null,
            scheduledLead.Lead_Notification_Sent_Date__c,
            'Lead with appointment should not have been notified'
        );
    }

    // ─── Test: non-pilot location leads are excluded ──────────────────────────────

    @isTest
    static void testNonPilotLeadExcluded() {

        Test.startTest();
        Database.executeBatch(new BatchTreatmentFinderLeadNotifier(), 50);
        Test.stopTest();

        Lead nonPilotLead = [
            SELECT Lead_Notification_Sent_Date__c
            FROM Lead
            WHERE FirstName = 'NonPilot' AND LastName = 'Patient'
            LIMIT 1
        ];

        System.assertEquals(
            null,
            nonPilotLead.Lead_Notification_Sent_Date__c,
            'Non-pilot location lead should not have been notified'
        );
    }

    // ─── Test: already-notified leads are excluded ────────────────────────────────

    @isTest
    static void testAlreadyNotifiedLeadSkipped() {

        Date originalDate = Date.today().addDays(-1);

        Test.startTest();
        Database.executeBatch(new BatchTreatmentFinderLeadNotifier(), 50);
        Test.stopTest();

        Lead alreadyNotifiedLead = [
            SELECT Lead_Notification_Sent_Date__c
            FROM Lead
            WHERE FirstName = 'Already' AND LastName = 'Notified'
            LIMIT 1
        ];

        System.assertEquals(
            originalDate,
            alreadyNotifiedLead.Lead_Notification_Sent_Date__c,
            'Already-notified lead should retain its original notification date'
        );
    }

    // ─── Test: schedulable fires batch ────────────────────────────────────────────

    @isTest
    static void testSchedulable() {

        Test.startTest();
        String cronExp = '0 0 7 * * ?';
        System.schedule('Test BatchTreatmentFinderLeadNotifier', cronExp, new BatchTreatmentFinderLeadNotifier());
        Test.stopTest();

        // If no exception thrown, the schedulable interface is wired up correctly
        System.assert(true, 'Schedulable executed without error');
    }
}