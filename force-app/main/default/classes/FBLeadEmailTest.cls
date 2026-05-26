@isTest
private class FBLeadEmailTest {
    
    @isTest
    static void testSendFBLeadNotification() {
        // Test data setup
        FB_Lead__c lead = new FB_Lead__c(
            FB_First_Name__c        = 'Test',
            FB_Last_Name__c         = 'Lead',
            FB_Phone__c             = '1234567890',
            FB_Email__c             = 'test@example.com',
            FB_Zip__c               = '12345',
            FB_Campaign_Name__c     = 'Test Campaign',
            
            // Extra fields for your Lead Qualification section
            FB_What_Service__c      = 'dentures',
            FB_How_Quickly__c       = 'within_the_next_30_days',
            FB_Using_Insurance__c   = 'yes',
            FB_Insurance_Provider__c= 'atnea'
        );
        
        insert lead;
        
        // Calling the method under test
        Test.startTest();
        FBLeadEmail.sendFBLeadNotification(new List<FB_Lead__c>{ lead },'');
        FBLeadEmail.sendFBLeadNotification(new List<FB_Lead__c>{ lead },'Messenger');
        Test.stopTest();
        
        // Verifying the results
        System.assertEquals(Date.today(), lead.FB_Notification_Sent_Date__c, 'Notification Sent Date should be today');
    }
}