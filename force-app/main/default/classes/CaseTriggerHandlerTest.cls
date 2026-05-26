@isTest
public class CaseTriggerHandlerTest {

    // --- Common test data
    @testSetup
    static void setupData() {
        // Create Accounts with required Record Types
        List<RecordType> acctRTs = [
            SELECT Id, Name FROM RecordType 
            WHERE SObjectType = 'Account'
        ];
        Map<String, Id> acctRTMap = new Map<String, Id>();
        for (RecordType rt : acctRTs) {
            acctRTMap.put(rt.Name, rt.Id);
        }

        // Practice account with Location ID
        Account practice = new Account(
            Name = 'Test Practice',
            RecordTypeId = acctRTMap.get('DDS Practice'),
            Location_ID__c = '12345'
        );
        insert practice;

        // Account with invalid Location for testing fallback
        Account badPractice = new Account(
            Name = 'Bad Practice',
            RecordTypeId = acctRTMap.get('DDS Practice'),
            Location_ID__c = ''
        );
        insert badPractice;

        // Blocked email entry
        insert new Email_Blacklist__c(Email__c = 'blocked@test.com');
    }

    // --- Test duplicate RedGate subject detection
    @isTest
    static void testDuplicateRedGateCases() {
        Id redGateRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('RedGate').getRecordTypeId();

        Case c1 = new Case(
            Subject = 'DuplicateCheck',
            Origin = 'Redgate',
            RecordTypeId = redGateRT
        );
        Case c2 = new Case(
            Subject = 'DuplicateCheck',
            Origin = 'Redgate',
            RecordTypeId = redGateRT
        );

        Test.startTest();
        Database.SaveResult sr1 = Database.insert(c1, false);
        Database.SaveResult sr2 = Database.insert(c2, false);
        Test.stopTest();

        System.assert(sr1.isSuccess(), 'First insert should succeed');
        System.assert(!sr2.isSuccess(), 'Second insert should be blocked as duplicate');
    }

    // --- Test subject parsing and location reassignment
    @isTest
    static void testSubjectLocationMapping() {
        Id sdeRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SDEmail').getRecordTypeId();
        Id acctId = [SELECT Id FROM Account WHERE Name = 'Bad Practice' LIMIT 1].Id;

        Case c = new Case(
            Subject = 'Need help at 12345',
            AccountId = acctId, // bad account
            Origin = 'Web',
            RecordTypeId = sdeRT
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        // After handler, Account should be reassigned
        Case inserted = [SELECT AccountId FROM Case WHERE Id = :c.Id];
        Account expected = [SELECT Id FROM Account WHERE Location_ID_5_digit__c = '12345' LIMIT 1];
        System.assertEquals(expected.Id, inserted.AccountId, 'Account should be reassigned from subject');
    }

    // --- Test blocked email prevents insert
    @isTest
    static void testBlockedEmail() {
        Id aceRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ACE Service').getRecordTypeId();

        Case c = new Case(
            Subject = 'Blocked case',
            SuppliedEmail = 'blocked@test.com',
            Origin = 'Web',
            RecordTypeId = aceRT
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(c, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Insert should fail due to blocked email');
        System.assert(sr.getErrors()[0].getMessage().contains('blocked@test.com'));
    }

    // --- Test afterInsert sets Location_Found__c for SevaredentPurchasing
    @isTest
    static void testAfterInsertLocationFound() {
        Id sevRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SevaredentPurchasing').getRecordTypeId();
        Id acctId = [SELECT Id FROM Account WHERE Name = 'Test Practice' LIMIT 1].Id;

        Case c = new Case(
            Subject = 'Purchase 12345',
            Origin = 'Phone',
            AccountId = acctId,
            RecordTypeId = sevRT
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case updated = [SELECT Location_Found__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(true, updated.Location_Found__c, 'Location_Found__c should be true');
    }

}