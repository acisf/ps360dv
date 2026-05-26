@isTest
private class PracticeMessageControllerTest {

    @isTest
    static void testGetPracticeMessages() {
        // Create a test Practice record
        Account testPractice = new Account(Name = 'Test Practice');
        insert testPractice;

        // Create test Practice_Message__c records
        Practice_Message__c msg1 = new Practice_Message__c(
            Name = 'Message 1',
            Practice__c = testPractice.Id,
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(1)
        );
        Practice_Message__c msg2 = new Practice_Message__c(
            Name = 'Message 2',
            Practice__c = testPractice.Id,
            Start_Date__c = Date.today().addDays(-3),
            End_Date__c = Date.today().addDays(-1)
        );
        Practice_Message__c msg3 = new Practice_Message__c(
            Name = 'Message 3',
            Practice__c = testPractice.Id,
            Start_Date__c = Date.today().addDays(-2),
            End_Date__c = null
        );
        insert new List<Practice_Message__c>{ msg1, msg2, msg3 };

        // Call the getPracticeMessages method in the controller
        Test.startTest();
        List<Practice_Message__c> messages = PracticeMessageController.getPracticeMessages(testPractice.Id,'All Messages');
        Test.stopTest();

        // Verify the returned messages
        System.assertEquals(2, messages.size(), 'Expected 2 messages to be returned');
        System.assertEquals('Message 3', messages[0].Name);
        System.assertEquals('Message 1', messages[1].Name);
    }


    @isTest
    static void testGetSchedulingRequirements() {
        Account testPractice = new Account(Name = 'test');
        insert testPractice;
        
        Scheduling_Requirements__c sr1 = new Scheduling_Requirements__c(
            Scheduling_Requirement_Note__c = 'Note 1',
            Scheduling_Requirement_Type__c = 'Implants',
            Practice__c = testPractice.Id
        );
        Scheduling_Requirements__c sr2 = new Scheduling_Requirements__c(
            Scheduling_Requirement_Note__c = 'Note 2',
            Scheduling_Requirement_Type__c = 'NDWP',
            Practice__c = testPractice.Id
        );
        insert new List<Scheduling_Requirements__c>{ sr1, sr2 };
        
        Test.startTest();
        List<Scheduling_Requirements__c> result = PracticeMessageController.getSchedulingRequirements(testPractice.Id);
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Incorrect number of scheduling requirements returned');
    }


    @IsTest
    static void testGetSpecialPromotions() {
        Account testPractice = new Account(Name = 'Test Practice');
        insert testPractice;

        Special_Promotions__c promo1 = new Special_Promotions__c(
            Practice__c = testPractice.Id,
            Promo_Start__c = Date.today(),
            Promo_Ends__c = Date.today().addDays(7)
        );
        Special_Promotions__c promo2 = new Special_Promotions__c(
            Practice__c = testPractice.Id,
            Promo_Start__c = Date.today().addDays(-7),
            Promo_Ends__c = Date.today().addDays(-1)
        );
        insert new List<Special_Promotions__c>{ promo1, promo2 };

        Test.startTest();
        List<Special_Promotions__c> result = PracticeMessageController.getSpecialPromotions(testPractice.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected 1 special promotion');
    }


    //
    // --------------------------------------------------------
    // NEW TESTS FOR getOfficeClosings & getOfficeIsClosed
    // --------------------------------------------------------
    //

    @isTest
    static void testGetOfficeClosings() {
        Account practice = new Account(Name = 'Office A');
        insert practice;

        // Active closing (should be returned)
        Office_Closing__c oc1 = new Office_Closing__c(
            Account__c = practice.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(1)
        );

        // Inactive closing (should NOT be returned)
        Office_Closing__c oc2 = new Office_Closing__c(
            Account__c = practice.Id,
            Start_Date__c = Date.today().addDays(30),
            End_Date__c = Date.today().addDays(32)
        );

        insert new List<Office_Closing__c>{ oc1, oc2 };

        Test.startTest();
        List<Office_Closing__c> results =
            PracticeMessageController.getOfficeClosings(practice.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return only active closings');
    }


    @isTest
    static void testGetOfficeIsClosed() {
        Account practice = new Account(
            Name = 'Test Office',
            IsClosed__c = true
        );
        insert practice;

        Test.startTest();
        List<Account> result =
            PracticeMessageController.getOfficeIsClosed(practice.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return exactly one account');
        System.assertEquals(true, result[0].IsClosed__c, 'Field should match expected value');
    }

}