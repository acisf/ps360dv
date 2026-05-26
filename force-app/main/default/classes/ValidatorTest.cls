@isTest
public class ValidatorTest {
    
    @isTest
    public static void runtest() {
        
        Domain__c  d = new Domain__c(); //valid top-level domain
        d.DomainName__c = 'COM';
        d.Valid__c =true;
        d.TopLevel__c=true;
        insert d;
        
        d = new Domain__c();
        d.DomainName__c = 'yabhoo.com'; //common error
        d.Valid__c = false;
        insert d;
        
        string email = 'johndoe@example.com';
        list<string> lstemail = new list<string>();
        lstemail.add(email);
        
        Validator.Entry e = new Validator.Entry();
        Validator.Entries ent = new Validator.Entries();
        Validator.Overview o = new Validator.Overview();
        Validator.Meta m = new Validator.Meta();
        Validator.Data data = new Validator.Data();
        Validator.setTopLevelDomains();
        Test.setMock(HttpCalloutMock.class, new ValidatorTestHttpMock());
        
        
        Test.startTest();
        
        
        System.assert(Validator.domains.size() == 1);
        System.assert(Validator.commonerrors.size() == 1);
        
        string domain =  Validator.getTopLevelDomain('johndoe@example.com');
        system.assert(domain=='com');
        
        domain =  Validator.getDomain('johndoe@example.com');
        system.assert(domain=='example.com');
        
        domain =  Validator.getTopLevelDomain('');
        system.assert(domain=='');
         domain =  Validator.getTopLevelDomain('john');
        system.assert(domain=='');
        
        system.assert(Validator.isValidEmail('johndoe@example.com'));
        system.assert(!Validator.isValidEmail('john'));
        system.assert(!Validator.isValidEmail(''));
        
        system.assert(Validator.hasValidTopLevelDomain('johndoe@example.com'));
        system.assert(Validator.hasValidDomain('john@example.com'));
        system.assertNotEquals(true, Validator.hasValidDomain('john@yabhoo.com'));  
       
        //test verifilia api
        string jobid = Validator.submitValidationJob(lstEmail);
        system.assert(jobid != '');
        
        lstEmail = Validator.getValidationJobFailures(jobid);
        System.assert(lstEmail.size()==1);
        
        Test.stopTest();
       
    }
    


}