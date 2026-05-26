@isTest
private class FBPracticeNotifierTest {
    
    static testMethod void runTest() {
        // Create test data 
        List<Account> lstacc = new List<Account>();
        List<FB_Lead__c> lstLeads = new List<FB_Lead__c>();
        
        
        Lead l = new Lead (FirstName='John',LastName='Doe',Email='jd@example.com',Company='Test');
        insert l;
        
        Account a1 = new Account(Name = 'Hot Springs - Arkansas',
                                 FB_Lead_Optin__c = true,
                                 FB_Notify_Practice__c = true,
                                 FB_Email_Campaign_Opt_In__c = true,
                                 Facebook_SMS1__c = '9191115555',
                                 Time_UTCOffset__c = -18000,
                                 Time_DSTOffset__c = 0);
        lstacc.add(a1);
        Account a2 = new Account(Name = 'York - Pennsylvania',
                                 FB_Lead_Optin__c = true,
                                 FB_Notify_Practice__c = true,
                                 FB_Email_Campaign_Opt_In__c = true,
                                 Facebook_SMS1__c = '9191116666',
                                 Facebook_SMS2__c = '9191117777',
                                 Time_UTCOffset__c = -18000,
                                 Time_DSTOffset__c = 0);
        lstacc.add(a2);
        insert lstacc; 
   
        Contact c1 = new Contact(FirstName = 'FDA', LastName = '09999', 
                                 AccountId = a1.Id,email = 'fda09999@affordabledentures.com',
                                 MobilePhone = '9191115555');
        insert c1;
        
        Contact c2 = new Contact(FirstName = 'FDA', LastName = '09998', 
                                 AccountId = a2.Id,email = 'fda09998@affordabledentures.com',
                                 MobilePhone = '9192225555');
        insert c2; 
        
        for(Integer i = 0; i<=1; i++){         
                FB_Lead__c lead = new FB_Lead__c();
            	lead.Lead__c = l.id;
                lead.FB_Practice__c = lstacc[i].id;
                lead.FB_First_Name__c = 'Test ' + i ;
                lead.FB_Last_Name__c = 'Lead ' + i;
                lead.FB_Email__c = 'Test' + i  + '.Lead' + i  + '@example.com';
                 lead.ArchieBot_Total_Score__c = 25;
                 lead.FB_Notification_Sent_Date__c = null;
                System.debug(lead);
                lstLeads.add(lead);
        }       		
        insert lstLeads;
        
        Test.startTest();
        
        // Call the method to test
        FBPracticeNotifier.sendFBFormLeadsNotification();
        FBPracticeNotifier.sendFBMessengerLeadsNotification();
        FBPracticeNotifier.sendSMSNotifications();
        Test.stopTest();
        
        // Add assertions here
        List<FB_Lead__c> lstFB = [SELECT id,Lead__c, FB_Form_Id__c,FB_Notification_Sent_Date__c,FB_Contact__c,FB_Practice__c, FB_Practice__r.FB_Lead_Optin__c, FB_Practice__r.FDA_Email__c,
                                  FB_Practice__r.FB_Practice_Email__c, FB_Practice__r.FB_Practice_CC_Email__c, FB_Practice__r.Time_Local__c,
                                  FB_First_Name__c, FB_Last_Name__c, FB_Email__c, FB_Phone__c, FB_Campaign_Name__c, CreatedDate,
                                  FB_Practice__r.Notify_Practice_Exclusions__c, FB_Zip__c, FB_Dental_Condition__c, FB_Current_Treatments__c,
                                  FB_How_Quickly__c, FB_Most_Important_Factor__c,  FB_Other_Dentists__c, FB_Interested_In_Financing__c,
                                  FB_Form__r.Name,SMS1_Notification_Sent_Date__c,SMS2_Notification_Sent_Date__c
                                  FROM  FB_Lead__c]; 
        
        for(FB_Lead__c lead: lstFB) {
            System.debug(lead);
        }
    
    }
}