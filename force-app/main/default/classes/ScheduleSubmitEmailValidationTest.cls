@isTest
public class ScheduleSubmitEmailValidationTest {

    @isTest
    public static void testEmail() {
        //  Setup test data 
        Account acc = new Account(Name = 'Test Practice', Location_Id__c = '1001');
        insert acc;

        FB_Lead__c fb = new FB_Lead__c(
            FB_Practice__c = acc.Id,
            FB_Campaign_Name__c = 'Test Campaign',
            FB_First_Name__c = 'John',
            FB_Last_Name__c = 'Doe',
            FB_Email__c = 'john@example.com',
            FB_Scheduled_1__c = Date.today()
        );
        insert fb;

        Practice_Review__c pr = new Practice_Review__c(
            pr_practice_id__c = '1001',
            pr_email__c = 'jane@example.com',
            pr_first_name__c = 'Jane',
            pr_last_name__c = 'Doe',
            pr_review_url__c = 'http://example.com',
            pr_valid_email__c = false
        );
        insert pr;
        Test.setMock(HttpCalloutMock.class, new ValidatorTestHttpMock());
        Test.startTest();
        String jobId = System.schedule('Test Email Validation', '0 0 0 3 9 ? 2099', new ScheduleSubmitEmailValidation());
        Test.stopTest();

    
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];
        
        System.assertEquals('0 0 0 3 9 ? 2099', ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2099-09-03 00:00:00', String.valueOf(ct.NextFireTime));
    }
}