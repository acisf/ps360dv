@isTest 
public class BatchValidateTrustpilotTest {
    
    @isTest()
    public static void test() {
        
        Account a = new Account(name='Test',location_id__c = '1001');
        insert a;
        
        Domain__c d = new Domain__c();
        d.DomainName__c = 'com';
        d.TopLevel__c = true;
        d.Valid__c = true;
        insert d;
        
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
        insert pr;
        
        Validator.setTopLevelDomains();
        
        System.Test.startTest();
        Database.executeBatch(new BatchValidateTrustpilot());
        System.Test.stopTest();
        
        pr = [SELECT Id,Name,  pr_Account__c, pr_brand_name__c, pr_city_state_zip__c,
              pr_Contact__c, pr_date_of_service__c, pr_email__c, pr_valid_email__c,
              pr_first_name__c, pr_last_name__c, pr_practice_id__c, pr_practice_id_5__c,
              pr_review_url__c, pr_date_sent__c
              FROM practice_review__c
              WHERE id =: pr.id
             ];
        
        system.debug(pr);
        system.assert(pr.pr_valid_email__c ==true);
        
        
    }
}