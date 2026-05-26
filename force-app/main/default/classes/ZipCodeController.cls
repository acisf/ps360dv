public class ZipCodeController {
 
    public zip_code__c calcNearestAccounts(Zip_Code__c zip){
        Account[] accounts;   
        integer size;
        
        accounts = [SELECT Id,BillingAddress
                    FROM Account                   
                    WHERE
                    (RecordType.Name = 'Schedule Assist' OR 
                     RecordType.Name = 'Registration' OR
                     RecordType.Name = 'Appointment') AND
                      IsClosed__c = false AND
                    (BillingLatitude != NULL OR BillingLongitude != NULL)
                     ORDER BY DISTANCE(BillingAddress, GEOLOCATION(:zip.latitude__c, :zip.longitude__c), 'mi') LIMIT 3];   
                    
        system.debug('Practices retrieved ' + accounts);
        
        size = accounts.size();
        if(size >= 1) {
            zip.Practice_1__c = accounts[0].id;
        }
        
        if(size >= 2) {
             zip.Practice_2__c = accounts[1].id;
        }
        
        if(size >= 3) {
             zip.Practice_3__c = accounts[2].id;
        }
        
        return zip;
    }
    
}