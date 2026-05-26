@isTest
public class BatchProcessEmailValidationTest {
    
    @isTest
    public static void testContactEmailOptOut(){        
        Email_Validation_Job__c evj = new Email_Validation_Job__c();
        evj.Job_Id__c = '142a9867-0e7d-47f9-953e-f834909281bd';
        evj.Submission_DateTime__c = Date.Today();
        evj.Type__c = 'Facebook';
        insert evj;
        
        Account acc = new Account(Name = 'Test Practice');
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'Batman';
        con.LastName = 'Superhero';
        con.Email = 'batman@gmail.com';
        con.AccountId = acc.Id;
        insert con;
        
           Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.VALIDATOR));

        
        Test.startTest();
        Id jobId = Database.executeBatch(new BatchProcessEmailValidation());
        Test.stopTest();
        
        Contact c = [Select Id, HasOptedOutOfEmail from contact where email = 'batman@gmail.com' limit 1];
        System.assertEquals(True, c.HasOptedOutOfEmail);
    }
    
    @isTest
    public static void testPracticeReview(){        
        Email_Validation_Job__c evj = new Email_Validation_Job__c();
        evj.Job_Id__c = '142a9867-0e7d-47f9-953e-f834909281bd';
        evj.Submission_DateTime__c = Date.Today();
        evj.Type__c = 'Practice Review';
        insert evj;
        
        Account acc = new Account(Name = 'Test Practice');
        insert acc;
        
        Practice_Review__c pr = new Practice_Review__c ();
        pr.pr_Account__c = null;  
        pr.pr_Contact__c = null;
        pr.pr_date_sent__c = null;
        pr.pr_date_of_service__c = 'March 15, 2020';
        pr.pr_email__c = 'batman@gmail.com';
        pr.pr_first_name__c = 'John';
        pr.pr_last_name__c = 'Doe';
        pr.pr_practice_id__c = '1001';
        pr.pr_review_url__c = 'http://www.example.com';        
        insert pr;
        
        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.VALIDATOR));
        
        Test.startTest();
        Id jobId = Database.executeBatch(new BatchProcessEmailValidation());
        Test.stopTest();
        
        Practice_Review__c pr1 = [Select Id, pr_valid_email__c from Practice_Review__c where pr_email__c = 'batman@gmail.com' limit 1];
        System.assertEquals(False, pr1.pr_valid_email__c);
    }

}