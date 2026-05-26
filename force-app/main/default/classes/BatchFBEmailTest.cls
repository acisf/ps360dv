@isTest
public class BatchFBEmailTest {
    
    @isTest
    static void runTest()
    {
        
        FB_Lead__c fb;
        FB_Lead__c fb2;
        FB_Lead__c fb3, fb4;
        
        Account a = new Account(name='Charlotte - North Carolina',Location_Id__c = '01002',
                                FB_Lead_Optin__c=true,FB_Discount_Optin__c=true,FB_LocalMed__c='test.com',FB_Notify_practice__c=true,FB_Email_campaign_opt_in__c=true);                               
        insert a;

        Account a2 = new Account(name='Unknown',Location_Id__c = '92001',
                                FB_Lead_Optin__c=true,FB_Discount_Optin__c=true,FB_LocalMed__c='test.com',FB_Notify_practice__c=true,FB_Email_campaign_opt_in__c=true);                               
        insert a2;
        
        Contact c = new Contact(firstname='John',lastname='Doe',email='jdoe@example.com');
        c.accountid = a.id;
        insert c;  
        
        Contact c2 = new Contact(firstname='Jane',lastname='Doe',email='janedoe@example.com');
        c2.accountid = a2.id;
        insert c2;  
        
        Facebook_Form__c form = new Facebook_Form__c(Name = 'North Carolina_Jan2021', Form_Id__c = '1344320092574013', Active__c = True);
        insert form;
        
        fb = new FB_Lead__c();
        fb.FB_Practice__c = a.id;
        fb.FB_Contact__c = c.id; 
        fb.FB_Scheduled_1__c = Date.today();        
        fb.FB_Status__c = 'Email';
        fb.FB_Form__c = form.id;
        insert fb;
        
        fb2 = new FB_Lead__c();
        fb2.FB_Practice__c = a.id;
        fb2.FB_Contact__c = c.id; 
        fb2.FB_Scheduled_2__c = Date.today();
        fb2.FB_Status__c = 'Email';
        fb2.FB_Form__c = form.id;
        insert fb2;
        
        fb3 = new FB_Lead__c();
        fb3.FB_Practice__c = a.id;
        fb3.FB_Contact__c = c.id; 
        fb3.FB_Scheduled_3__c = Date.today();
        fb3.FB_Status__c = 'Email';
        insert fb3;

        fb4 = new FB_Lead__c(); 
        fb4.FB_Practice__c = a2.id;   
        fb4.FB_Practice_Id__c = '92001';    
        fb4.FB_Contact__c = c2.id; 
        fb4.FB_Scheduled_1__c = Date.today();        
        fb4.FB_Status__c = 'Email';
        fb4.FB_Form__c = form.id;
        insert fb4;
        
        
        Test.StartTest();          
        
        List<FB_Lead__c> lstFB = new List<FB_Lead__c>();  
        
        lstFB = [SELECT Id, FB_Contact__c, FB_Scheduled_1__c,FB_Scheduled_2__c,FB_Scheduled_3__c,FB_Message_Id__c,FB_1st_Contact_Time__c,
                 FB_2nd_Contact_Time__c, FB_3rd_Contact_Time__c
                 FROM FB_Lead__c 
                 ORDER BY CreatedDate]; 
        
        Id batchJobId = Database.executeBatch(new BatchFBEmail(), 10);
        
        Test.stopTest();
        
        lstFB = [SELECT Id, FB_Contact__c,FB_Message_Id__c,FB_1st_Contact_Time__c,
                 FB_2nd_Contact_Time__c, FB_3rd_Contact_Time__c
                 FROM FB_Lead__c 
                 ORDER BY CreatedDate]; 
        
        for(FB_Lead__c f:lstFB) {
            system.debug(f);
        }
        System.assertEquals(lstFB[0].FB_1st_Contact_Time__c, Date.today());
        System.assertEquals(lstFB[1].FB_2nd_Contact_Time__c, Date.today());
        System.assertEquals(lstFB[2].FB_3rd_Contact_Time__c, NULL);
        System.assertEquals(lstFB[3].FB_1st_Contact_Time__c, Date.today());
        
    }
    
}