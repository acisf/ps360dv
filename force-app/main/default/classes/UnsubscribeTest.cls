@isTest
public class UnsubscribeTest {
    
    static testMethod void testUnsubscribe() {
        
        // Create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env   = new Messaging.InboundEnvelope();
        
        // Create a new test Lead and insert it in the Test Method        
        Lead l = new lead(firstName='Rasmus', 
                          lastName='Mencke',
                          Company='Salesforce', 
                          Email='rmencke@salesforce.com', 
                          HasOptedOutOfEmail=false);
        insert l;
        
        // Create a new test Contact and insert it in the Test Method  
        id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account acct = new Account(name='Danville - Virginia',recordtypeid=RecordTypeIdAcct);     
        insert acct;
        Contact c = new Contact(firstName='Rasmus', 
                                lastName='Mencke', 
                                Email='rmencke@salesforce.com', 
                                HasOptedOutOfEmail=false,
                               AccountId = acct.id);
        insert c;
        
        // test with subject that matches the unsubscribe statement
        email.subject = 'test unsubscribe test';
        env.fromAddress = 'rmencke@salesforce.com';
        
        // call the class and test it with the data in the testMethod
        unsubscribe unsubscribeObj = new unsubscribe();
        unsubscribeObj.handleInboundEmail(email, env );
        
        
        // Create a new email and envelope object
        email = new Messaging.InboundEmail();
        env = new Messaging.InboundEnvelope();
        
        // Create a new test Lead and insert it in the Test Method        
        l = new lead(firstName='Rasmus', 
                          lastName='Mencke',
                          Company='Salesforce', 
                          Email='rmencke@salesforce.com', 
                          HasOptedOutOfEmail=false);
        insert l;
        
        // Create a new test Contact and insert it in the Test Method    
        c = new Contact(firstName='Rasmus', 
                                lastName='Mencke', 
                                Email='rmencke@salesforce.com', 
                                HasOptedOutOfEmail=false,
                                AccountId = acct.Id);
        insert c;
        
        // Test with a subject that does Not contain unsubscribe
        email.subject = 'test';
        env.fromAddress = 'rmencke@salesforce.com';
        
        // call the class and test it with the data in the testMethod
        unsubscribeObj = new unsubscribe();
        unsubscribeObj.handleInboundEmail(email, env );                     
    }    
    
}