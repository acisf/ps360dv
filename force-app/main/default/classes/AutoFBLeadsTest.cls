@isTest
public class AutoFBLeadsTest {
    
    @isTest static void testCallout() {
        
        Account a;
        
        //test data
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        a = new Account(name='Charlotte - North Carolina',Location_Id__c = '1002',FB_Notify_practice__c=true,fb_Email_campaign_opt_in__c=true,
                        FB_Call_Campaign_Opt_In__c=true,Brand__c='Affordable Dentures & Implants', recordtypeid=RecordTypeIdAcct);
        insert a;	
        
        RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Test Practice').getRecordTypeId();
        a = new Account(name='Test',Location_Id__c = '92001',FB_Notify_practice__c=true,fb_Email_campaign_opt_in__c=true,
                        FB_Call_Campaign_Opt_In__c=true,recordtypeid=RecordTypeIdAcct);
        insert a;
        
        Contact c = new Contact();
        c.AccountId = a.id;
        c.FirstName = 'Jane';
        c.LastName = 'Doe';
        c.Email = 'jane.doe@example.com';
        insert c;
        
        Facebook_Form__c fbForm = new Facebook_Form__c();
        Facebook_Setting__c fbsetting = new Facebook_Setting__c();
        
        fbForm.Form_Id__c = '1234';  
        insert fbForm;
        
        fbsetting.API_Token__c = '1234';
        insert fbsetting;
        
        Zip_Code__c zip = new Zip_Code__c();
        zip.Zip__c = '27606';
        zip.practice_1__c = a.id;
        insert zip;
        
        AutoFBLeads auto = new AutoFBLeads();
        AutoFBLeads.data d = new AutoFBleads.data();
        AutoFBLeads.field_data fd = new AutoFBleads.field_data();
        AutoFBLeads.Error err = new AutoFBleads.Error(); 
        
        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.FACEBOOK));
        
        Test.startTest();        
        
        System.assert(d !=null);
        System.assert(fd != null);
        System.assert(err != null);
        
        
        HttpResponse res = AutoFBLeads.getLeadsFromAPI(fbForm,fbsetting.API_Token__c);
        System.debug(res.getBody());
        
        String contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        System.assertEquals(200, res.getStatusCode()); 
        
        AutoFBLeads.createLeadObjects(res,fbForm);        
        System.assertEquals(3,AutoFBLeads.lstDownloadedLeads.size());   
        System.assertEquals(3,AutoFBLeads.lstLeads.size());   
        
        AutoFBLeads.createContactObjects();
        System.assertEquals(2,AutoFBLeads.lstContact.size());
        System.assertEquals(1,AutoFBLeads.mapContact.size());
        AutoFBLeads.saveContacts();
        AutoFBLeads.saveLeads(); 
        System.assertEquals(3,AutoFBLeads.lstLeads.size()); 
        //List<Case> lstCases = AutoFBLeads.createCaseObjects();
        //AutoFBLeads.saveCases();
        //System.assertEquals(2,lstCases.size());
    }
}