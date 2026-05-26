@isTest
public class BatchFBMessengerEmailTest {
    
    @isTest
    static void runTest()
    {
        
        FB_Lead__c fb, fb2;
        Account a,a2;
        Lead l,l2;   
        List<FB_Lead__c> lstFB;
        
        a = new Account(name='Charlotte - North Carolina',Location_Id__c = '01002',
                        FB_Lead_Optin__c=true,FB_Discount_Optin__c=true,FB_LocalMed__c='test.com',FB_Notify_practice__c=true,FB_Email_campaign_opt_in__c=true);                               
        insert a;
        
        
        l = new Lead(firstname='John',lastname='Doe',email='jdoe@example.com',company='Charlotte - North Carolina');
        l.FB_Practice__c = a.id;
        insert l;  
        
        l2 = new Lead(firstname='Jane',lastname='Doe',email='janedoe@example.com',company='test');
        l2.FB_Practice__c = null;
        insert l2;  
        
        fb = new FB_Lead__c();
        fb.FB_Practice__c = a.id;
        fb.Lead__c = l.id; 
        fb.FB_Scheduled_1__c = Date.today();  
        insert fb;
        
        fb2 = new FB_Lead__c();
        fb2.FB_Practice__c = null;
        fb2.Lead__c = l2.id; 
        fb2.FB_Scheduled_2__c = Date.today();
        insert fb2;
        
        Test.StartTest();          
        Id batchJobId = Database.executeBatch(new BatchFBMessengerEmail(), 10);  
        Test.stopTest();
        
        lstFB = [SELECT Id, Lead__c,FB_Message_Id__c,FB_1st_Contact_Time__c,
                 FB_2nd_Contact_Time__c, FB_3rd_Contact_Time__c
                 FROM FB_Lead__c 
                 ORDER BY CreatedDate]; 
        
        for(FB_Lead__c f:lstFB) {
            system.debug(f);
        }
        
        System.assertEquals(Date.today(), lstFB[0].FB_1st_Contact_Time__c);
        System.assertEquals(Date.today(), lstFB[1].FB_2nd_Contact_Time__c);
        
    }
    
}