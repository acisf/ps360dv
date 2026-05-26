@istest
public class BatchZipCodesTest {
    
    static testmethod void testZipCodeController() {
        zip_code__c zip = new zip_code__c();
        zip.state__c = 'NC';
        zip.zip__c = '27606';
        zip.latitude__c = 35.7400;
        zip.longitude__c = -78.7200;
        insert zip;
        
         Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account a1 = new Account(name = 'Garner',recordtypeid = recordtypeidacct,billinglatitude=35.7,billinglongitude=-78.7,billingstreet='142 Shenstone Blvd',billingstate='North Carolina',billingcity='Garner');
        insert a1;
        Account a2 = new Account(name = 'Durham',recordtypeid = recordtypeidacct,billinglatitude=35.7,billinglongitude=-78.7,billingstreet='5606 Apex Highway Durham',billingstate='North Carolina',billingcity='Durham');
        insert a2;
         Account a3 = new Account(name = 'Fayetteville',recordtypeid = recordtypeidacct,billinglatitude=35.7,billinglongitude=-78.7,billingstreet='3055 Sanderosa Road',billingstate='North Carolina',billingcity='Fayetteville');
        insert a3;
       
        a1=[select id, name,billinglatitude,billinglongitude from account where id =: a1.id];
        system.debug(a1);
        
        a2=[select id, name,billinglatitude,billinglongitude from account where id =: a2.id];
        system.debug(a2);
        
        a3=[select id, name,billinglatitude,billinglongitude from account where id =: a3.id];
        system.debug(a3);
        
        Test.startTest();
        BatchZipCodes zb = new BatchZipCodes();
        Database.executeBatch(zb);
       
        
    }
    
    
}