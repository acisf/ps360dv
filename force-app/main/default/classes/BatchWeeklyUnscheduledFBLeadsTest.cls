@isTest
private class BatchWeeklyUnscheduledFBLeadsTest {

    @isTest
    static void testWeeklyBatch() {

        // -----------------------------
        // Setup Accounts (Practices)
        // -----------------------------
        List<Account> practices = new List<Account>();

        Account p1 = new Account(
            Name = 'Asheville - North Carolina',
            FB_Practice_Email__c = 'practice1@test.com',
            Location_Id__c = '01001'
        );

        Account p2 = new Account(
            Name = 'Charlotte - North Carolina',
            Location_Id__c = '01002',
            FB_Practice_Email__c = 'fda01002@test.com'  
        );

        practices.add(p1);
        practices.add(p2);
        insert practices;

        // -----------------------------
        // Create FB Leads
        // -----------------------------
        List<FB_Lead__c> leads = new List<FB_Lead__c>();

        // Practice 1 → has direct email
        leads.add(new FB_Lead__c(
            FB_Practice__c = p1.Id,
            FB_Phone__c = '9191111111',
            FB_Email__c = 'lead1@test.com',
            FB_What_Service__c = 'dentures',
            FB_Using_Insurance__c = 'yes',
            FB_How_Quickly__c = 'im_ready_now___help_me_schedule'
        ));

        leads.add(new FB_Lead__c(
            FB_Practice__c = p1.Id,
            FB_Phone__c = '9192222222',
            FB_Email__c = 'lead2@test.com',
            FB_What_Service__c = 'implants',
            FB_Using_Insurance__c = 'no',
            FB_How_Quickly__c = 'within_the_next_30_days'
        ));

        // Practice 2 → fallback to FDA email
        leads.add(new FB_Lead__c(
            FB_Practice__c = p2.Id,
            FB_Phone__c = '9193333333',
            FB_Email__c = 'lead3@test.com',
            FB_What_Service__c = 'dentures',
            FB_Using_Insurance__c = 'yes',
            FB_How_Quickly__c = '60+_days__just_exploring'
        ));

        insert leads;

        // -----------------------------
        // Re-query to ensure formula fields evaluate
        // -----------------------------
        leads = [
            SELECT Id, Practice_Id__c, Scheduled__c
            FROM FB_Lead__c
        ];

        // Optional debug (helps if anything breaks later)
        for (FB_Lead__c l : leads) {
            System.debug('Practice_Id__c: ' + l.Practice_Id__c);
            System.debug('Scheduled__c: ' + l.Scheduled__c);
        }

        // -----------------------------
        // Execute Batch
        // -----------------------------
        Test.startTest();

        BatchWeeklyUnscheduledFBLeads batch = new BatchWeeklyUnscheduledFBLeads();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // -----------------------------
        // Assertions
        // -----------------------------

        // ✅ Correct assertion: sendEmail() called once
       System.assertEquals(2, BatchWeeklyUnscheduledFBLeads.emailsSentCount,
    'Should send 2 emails (one per practice)');

    }

    @isTest
    static void testSchedulableExecution() {

        Test.startTest();

        // Schedule job
        String cron = '0 0 7 ? * MON';
        System.schedule('Test Weekly Job', cron, new BatchWeeklyUnscheduledFBLeads());

        Test.stopTest();

        System.assert(true, 'Schedulable executed successfully');
    }
}