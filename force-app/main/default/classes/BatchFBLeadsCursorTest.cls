@isTest
public class BatchFBLeadsCursorTest {

    @isTest
    public static void testFBLeadsByBatch(){
        Account a;
        
        //test data
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        a = new Account(name='Charlotte - North Carolina',Location_Id__c = '1002',FB_Notify_practice__c=true,fb_Email_campaign_opt_in__c=true,
                        recordtypeid=RecordTypeIdAcct);
        insert a; 
        
        Facebook_Form__c fbForm = new Facebook_Form__c();   
        Facebook_Setting__c fbsetting = new Facebook_Setting__c();  
        fbForm.Form_Id__c = '1234';  
        fbForm.Active__c = true;
        fbForm.FB_After_Cursor__c = '1234';
        insert fbForm;
        
        fbsetting.API_Token__c = '1234';
        insert fbsetting;

        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.FACEBOOK));

        Test.startTest();
        BatchFBLeadsCursor fb_leads = new BatchFBLeadsCursor();
        Id batchId = Database.executeBatch(fb_leads); 
        Test.stopTest();
        
        
        List<FB_Lead__c> fbLead = [Select id from FB_Lead__c where createddate = today];
        System.assert(fbLead.size() > 0);
        
    }
}