@isTest(isParallel=false)
public class FBLeadSMSTest {
    
    @testSetup
    static void setupData() {
        // Create practice account
        Account practice = new Account(
            Name = 'UT Test Practice',
            FB_Lead_Optin__c = true,
            FB_Notify_Practice__c = true,
            FB_Email_Campaign_Opt_In__c = true
        );
        insert practice;

        // Create contact for the practice
        Contact c1 = new Contact(
            FirstName = 'UT',
            LastName = 'Contact1',
            AccountId = practice.Id,
            Email = 'contact1@example.com',
            MobilePhone = '9195551111'
        );
        insert c1;

        practice.FB_SMS_Contact1__c = c1.Id;

        // Compute a UTC offset that guarantees local time inside 7:00–20:00
        Integer targetLocalHour = 12; // aim for 12 PM local time
        Integer utcHour = System.now().hour();
        Integer safeOffsetSeconds = (targetLocalHour - utcHour) * 3600;

        practice.Time_UTCOffset__c = safeOffsetSeconds;
        practice.Time_DSTOffset__c = 0;

        update practice;

        // Create a Facebook lead linked to the practice
        FB_Lead__c lead = new FB_Lead__c(
            FB_Practice__c = practice.Id,
            FB_First_Name__c = 'Lead',
            FB_Last_Name__c = 'Tester',
            FB_Email__c = 'lead@example.com',
            Lead__c = null
        );
        insert lead;
    } 
    // helper to clear static state
    private static void clearStaticState() {
        if (FBLeadSMS.contactIds != null) FBLeadSMS.contactIds.clear();
        if (FBLeadSMS.contactMobileNos != null) FBLeadSMS.contactMobileNos.clear();
        if (FBLeadSMS.contactTimeZone != null) FBLeadSMS.contactTimeZone.clear();
    }
    
    @isTest
    static void testSendFBLeadSMS_createsMessageAndUpdatesLead() {
        clearStaticState();
        
        FB_Lead__c testLead = [
            SELECT Id, FB_Practice__c, FB_First_Name__c, FB_Last_Name__c, FB_Email__c,
            SMS1_Notification_Sent_Date__c, SMS2_Notification_Sent_Date__c, Lead__c
            FROM FB_Lead__c
            LIMIT 1
        ];
        
        Integer before = [SELECT count() FROM TwilioSF__Message__c];
        
        Test.startTest();
        FBLeadSMS.sendFBLeadSMS(new List<FB_Lead__c>{ testLead });
        Test.stopTest();
        
        Integer after = [SELECT count() FROM TwilioSF__Message__c];
        System.assertEquals(before + 1, after, 'Twilio message count should have increased by 1');
        
        // reload lead to confirm timestamp updated
        testLead = [
            SELECT SMS1_Notification_Sent_Date__c, SMS2_Notification_Sent_Date__c
            FROM FB_Lead__c
            WHERE Id = :testLead.Id
        ];
        System.assertNotEquals(null, testLead.SMS1_Notification_Sent_Date__c,
                               'Lead should have SMS1 timestamp set');
    }
    
    @isTest
    static void testSendFBLeadSMS_noContact_createsNoMessage() {
        clearStaticState();
        
        Account noContact = new Account(
            Name = 'NoContactPractice',
            FB_Lead_Optin__c = true,
            FB_Notify_Practice__c = true,
            FB_Email_Campaign_Opt_In__c = true
        );
        insert noContact;
        
        FB_Lead__c leadNoContact = new FB_Lead__c(
            FB_Practice__c = noContact.Id,
            FB_First_Name__c = 'No',
            FB_Last_Name__c = 'Contact',
            FB_Email__c = 'nocontact@example.com'
        );
        insert leadNoContact;
        
        Integer before = [SELECT count() FROM TwilioSF__Message__c];
        
        Test.startTest();
        FBLeadSMS.sendFBLeadSMS(new List<FB_Lead__c>{ leadNoContact });
        Test.stopTest();
        
        Integer after = [SELECT count() FROM TwilioSF__Message__c];
        System.assertEquals(before, after,
                            'No Twilio messages should be created when no contacts exist');
    }
    
    @isTest
    static void testSendFBLeadSMS_notifyDisabled_createsNoMessage() {
        clearStaticState();
        
        Account disabled = new Account(
            Name = 'DisabledPractice',
            FB_Lead_Optin__c = true,
            FB_Notify_Practice__c = false, // <== notify disabled
            FB_Email_Campaign_Opt_In__c = true
        );
        insert disabled;
        
        Contact c1 = new Contact(
            FirstName = 'Disabled',
            LastName = 'Contact',
            AccountId = disabled.Id,
            Email = 'disabled@example.com',
            MobilePhone = '9195552222'
        );
        insert c1;
        
        disabled.FB_SMS_Contact1__c = c1.Id;
        update disabled;
        
        FB_Lead__c disabledLead = new FB_Lead__c(
            FB_Practice__c = disabled.Id,
            FB_First_Name__c = 'Skip',
            FB_Last_Name__c = 'Notify',
            FB_Email__c = 'skip@example.com'
        );
        insert disabledLead;
        
        Integer before = [SELECT count() FROM TwilioSF__Message__c];
        
        Test.startTest();
        FBLeadSMS.sendFBLeadSMS(new List<FB_Lead__c>{ disabledLead });
        Test.stopTest();
        
        Integer after = [SELECT count() FROM TwilioSF__Message__c];
        System.assertEquals(before, after,
                            'No messages should be created when practice notify flag is false');
    }
}