@istest
public class NotificationEmailTest {

    @isTest
    public static void testSendEmail(){
    
        Account newAcc = new Account();
        newAcc.name='test';
        insert newAcc;
        Id pracEmployeeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Practice Employee').getRecordTypeId();
        Id aceServiceId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ACE Service').getRecordTypeId();
        
        List<Contact> con=new List<Contact>();
        Integer i = 1;
        for(i=1; i<5; i++){
            Contact cn = new Contact();
        	cn.AccountId = newAcc.id;
        	cn.FirstName = 'ABC';
        	cn.lastname='Testing' + i;
        	cn.email='test'+i+'@test.com';
            cn.RecordTypeId = pracEmployeeId;
            con.add(cn);
        }
        insert con;
        
        List<Case> cases = new list<Case>();
        For(i=0; i<4 ; i++){
            Case c = new Case();
        	c.AccountId = newAcc.id;
            if(i == 0)
            {
        		c.ContactId = con[i].id;
                c.Team__c = 'Dental Equipment Repairs';
                c.IsCreatedInConsole__c = True;
                c.Category__c = 'Handpiece';
                c.RecordTypeId = aceServiceId;
            }
            else if(i == 1)
            {                
                c.Team__c = 'Dental Equipment Repairs';
                c.IsCreatedInConsole__c = True;
                c.Category__c = 'Large Equipment';
                c.RecordTypeId = aceServiceId;
            }
            else if (i == 2)
            {               
                c.Team__c = 'IT';
                c.IsCreatedInConsole__c = True;
                c.RecordTypeId = aceServiceId;
            }
            else
            {
                c.Team__c = 'Dental Equipment Repairs';
                c.IsCreatedInConsole__c = False;
                c.Category__c = 'Small Equipment';
                c.RecordTypeId = aceServiceId;
            }
        	c.SuppliedEmail = con[i].Email;
            cases.add(c);
        }
        insert cases;
        
        List<Id> caseid = new List<Id>();
        for(i=0; i<4; i++)
        	caseid.add(cases[i].id);
        
		//RepairsSendEmail.repairEmail(caseid);
		NotificationEmail.sendNotificationEmail(caseid);
		Integer invocations = Limits.getEmailInvocations();
        System.debug('Invocations: ' + invocations);
        System.assert(invocations > 0);
    }

}