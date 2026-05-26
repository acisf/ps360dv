@isTest
public class ZetaUserTriggerHandlerTest {
    
    static testmethod void runTest() {
        
        Id saRT  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Id pRT  = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
        List<Zeta_User__c> lstNewZU = new List<Zeta_User__c>();
        
        Account a = new Account();
        a.Name = 'Test';
        a.Location_ID__c = '20123';
        a.RecordTypeId = saRT;
        insert a;
        
        Contact c = new Contact();
        c.LastName = 'Doe';
        c.FirstName = 'John';
        c.MobilePhone = '9195551212';
        c.AccountId = a.id;
        c.RecordTypeId = pRT;
        c.Pat_ID_DB__c = '';
        insert c;
        
        c=[SELECT Id, LastName, FirstName, MobilePhone, AccountId, Contact_Key__c FROM Contact WHERE Id =: c.id];
        System.debug(c);
        
        Zeta_User__c zUser1 = new Zeta_User__c();
        zUser1.JSON__c = '{"user_id":"12345","signed_up_at":"06/04/2018","patient_id":"33600","practice_id":"20123","first_name":"Joe","last_name":"Frazier","contacts":[{"contact_type":"phone","contact_value":"8134797160"}],"home_phone":"8418792479","mobile_phone":"8134797160","work_phone":"","phone_appointment":"8418792479","street":"8026 Shady Wood Dr.","street2":"","city":"Tampa","state":"FL","zip":"33617","gender":"m","dob":"12/21/1998","chartid":"034374","new_patient":"false","dismissed":"false"}';
        
        Zeta_User__c zUser2 = new Zeta_User__c();
        zUser2.JSON__c = '{"user_id":"67891","signed_up_at":"06/04/2018","patient_id":"32200","practice_id":"20123","first_name":"John","last_name":"Doe","contacts":[{"contact_type":"phone","contact_value":"9195551212"}],"home_phone":"","mobile_phone":"9995551212","work_phone":"","phone_appointment":"","street":"123 Any St.","street2":"","city":"Tampa","state":"FL","zip":"33617","gender":"m","dob":"12/21/1920","chartid":"3332212","new_patient":"false","dismissed":"false"}';
        
        
        lstNewZU.add(zUser1);
        lstNewZU.add(zUser2);
        
        test.startTest();
        insert lstNewZU;
        test.stopTest();
        
        
        lstNewZU  = [select id, user_id__c, last_name__c, Contact__c from Zeta_User__c];
        for(Zeta_User__c zu: lstNewZU) {
            System.debug(zu);
            if(zu.user_id__c =='12345') {
                system.assert(zu.last_name__c == 'Frazier');
            }
               if(zu.user_id__c =='67891') {
                system.assert(zu.last_name__c == 'Doe');
            }
            
        }
        
    }
}