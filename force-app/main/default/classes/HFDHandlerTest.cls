@isTest
public class HFDHandlerTest {
    
    static testMethod void testEmailHandler(){
        
        HFDHandler handler = new HFDHandler();
        
        //test data for practice
        
        String rt='Schedule Assist';
        Id rtId= Schema.SObjectType.Account.getRecordTypeInfosByName().get(rt).getRecordTypeId();
        
        Account a = new Account();
        a.RecordTypeId = rtId;
        a.Name = 'Test Practice';
        a.Location_ID__c = '1001';
        insert a;        
        
        // setup the data for the html email
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = 'HFD Lead -- Location 1001';
        email.htmlBody = 'Location::1001';
        env.fromAddress = 'johndoe@example.com';
        
        //test getting email body
        String body = handler.getEmailBody(email);
        System.Assert(body!=null);
        
        // setup the data for the plaintext email
        email = new Messaging.InboundEmail() ;
        env = new Messaging.InboundEnvelope();
        email.subject = 'HFD Lead -- Location 1001';
        email.plainTextBody = 'Location::1001\nFirstName::John\nLastName::Doe\nPhoneNumber::+15555551212\nEmail::johndoe@example.com';
        env.fromAddress = 'johndoe@example.com';
        
        //test getting email body
        body = handler.getEmailBody(email);
        System.Assert(body!=null);
        
        //test getting location
        String strLocation = handler.getLocationFromSubject(email.subject);
        System.Assert(strLocation == '01001');
        
        //test getting practice object
        Account acct = handler.getPracticeFromLocation(strLocation);
        System.Assert(acct.Location_Id_5_digit__c == strLocation);
        
        //test creating contact
        Map<string,string> fields = handler.getFieldsFromEmailBody(body);
        Contact cnt = handler.createContact(a,fields);
        System.Assert(cnt.FirstName == 'John');
        insert cnt;
        
        fields = handler.getFieldsFromEmailBody(body);
        cnt = handler.createContact(null,fields);
        System.Assert(cnt.FirstName == 'John');
        
        //test creating a case
        Case c = handler.createCase(email.subject,body,a.id,cnt);
        System.Assert(c.Subject == email.subject);
        
        Case c2 = handler.createCase(null,null,null,null);
        System.Assert(String.isEmpty(c2.Subject));
        
        Contact cnt2 = new Contact();
        cnt2.FirstName = 'John';
        cnt2.LastName = 'Doe';
        cnt2.AccountId = a.id;
        insert cnt2;
        Case c3 = handler.createCase(null,null,a.id, cnt2);        
        
        //test the entire process        
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        System.Assert(result.success);
    }
    
}