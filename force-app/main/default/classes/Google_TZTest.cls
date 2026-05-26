@isTest
public class Google_TZTest {
    @isTest static void testCallout() {
        
        Account a;
        
        //test data
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        a = new Account(name='Folsom - Pennsylvania',Location_Id__c = '06302',recordtypeid=RecordTypeIdAcct);
        a.BillingLatitude = 39.88094;
        a.BillingLongitude = -75.33901;
        insert a; 
        
        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.GOOGLE));
        Test.startTest();
        
        Set<Id> accountids = new Set<Id>();
        accountids.add(a.id); 
        
        HttpResponse res = Google_TZ.callGoogleAPI(a);
        System.assert(res.getStatusCode() == 200); 
        System.assert(Google_TZ.getAccounts(accountids).size() > 0);
        Google_TZ.getTimeZoneData(accountids);
        system.debug(Google_tz.getAccounts(accountids)); 
        Google_TZ.updateAccountTimeZoneDta(New Id[]{a.id});
        System.assert(Google_TZ.getAccounts(accountids).size() > 0);
        Test.stopTest();
    }
}