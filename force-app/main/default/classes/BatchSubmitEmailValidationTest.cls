@isTest
public class BatchSubmitEmailValidationTest {
    @isTest
    public static void testFBEmailValidity(){
        Account acc = new Account(Name = 'Test Practice');
        insert acc;
        
        FB_Lead__c fb1;      
        
        fb1 = new FB_Lead__c();
        fb1.FB_Practice__c = acc.id;
        fb1.FB_Campaign_Name__c = 'ACI-ADI_Social_Birmingham_7330_N_ImplantEagle_Facebook_NewCustomers_LeadGeneration';
        fb1.FB_First_Name__c = 'John';
        fb1.FB_Last_Name__c = 'Doe';
        fb1.FB_Email__c = 'john.doe@ymail.comm';
        fb1.FB_Scheduled_1__c = Date.today();
        insert fb1;      
        
        Test.setMock(HttpCalloutMock.class, new ValidatorTestHttpMock());        
        Test.startTest();
        Id jobid = Database.executeBatch(new BatchSubmitEmailValidation('Facebook'));
        Test.stopTest();
        
        List<Email_Validation_Job__c> evj = [Select Id from Email_Validation_Job__c where createddate = today];
        System.assertEquals(1, evj.size());
        
    }
    
     @isTest
    public static void testPREmailValidity(){
        Account a = new Account(name='Test',location_id__c = '1001');
        insert a;
        
        Practice_Review__c pr = new Practice_Review__c ();
        pr.pr_Account__c = null;  
        pr.pr_Contact__c = null;
        pr.pr_date_sent__c = null;
        pr.pr_date_of_service__c = 'March 15, 2020';
        pr.pr_email__c = 'jdoe@affordablecare.com';
        pr.pr_first_name__c = 'John';
        pr.pr_last_name__c = 'Doe';
        pr.pr_practice_id__c = '1001';
        pr.pr_review_url__c = 'http://www.example.com';   
        pr.pr_valid_email__c = false;
        insert pr;
        
        Test.setMock(HttpCalloutMock.class, new ValidatorTestHttpMock());        
        Test.startTest();
        Id jobid = Database.executeBatch(new BatchSubmitEmailValidation('Practice Review'));
        Test.stopTest();
        
        List<Email_Validation_Job__c> evj = [Select Id from Email_Validation_Job__c where createddate = today];
        System.assertEquals(1, evj.size());
    }

}