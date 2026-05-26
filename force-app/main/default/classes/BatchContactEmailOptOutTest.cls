@isTest
public class BatchContactEmailOptOutTest {

    @isTest
    public static void testContactEmailOptOut(){        
        Email_Validation_Job__c evj = new Email_Validation_Job__c();
        evj.Job_Id__c = '142a9867-0e7d-47f9-953e-f834909281bd';
        evj.Submission_DateTime__c = Date.Today();
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
        Id jobId = Database.executeBatch(new BatchContactEmailOptOut());
        Test.stopTest();
        
        Contact c = [Select Id, HasOptedOutOfEmail from contact where email = 'batman@gmail.com' limit 1];
        System.assertEquals(True, c.HasOptedOutOfEmail);
    }
}