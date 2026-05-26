public with sharing class AccountGeoLogic {
    
    public class AccountGeoLogicException extends Exception {}
    static Integer distanceCalc = 1000;
    public Contact cont {get; set;}
    public String accId {get; set;} 
    ApexPages.StandardController std;
    
    public String googleAPIKey { 
        get {
            if (googleAPIKey == null || googleAPIKey == '') {
                googleAPIKey = Google_API_Key_Gen__c.getValues('Default').Key_Prod__c;
            }
            return googleAPIKey;
        } 
        private set; 
    }
    
    public AccountGeoLogic(ApexPages.StandardController std) {
        this.std = std;
        cont = new Contact();
        if (std.getId() == null) {            
        } else {
            cont = (Contact)std.getRecord().clone(false, true, false, false);
        }
    }
    
    @RemoteAction 
    public static List<sObject> getAccountByGeoLoc(Decimal dLat, Decimal dLong, Integer offset) {
        List<Account> lstGeoAcc = new List<Account>();
        lstGeoAcc = [
            SELECT Id, Name, AccountNumber, BillingStreet, BillingState, BillingPostalCode, BillingCity,
            BillingLatitude, BillingLongitude, Service_Codes__c, RecordType.Name, Record_Type__c, 
            IsClosed__c, Insurance_Accepted__c, Medicaid_Type__c
            FROM Account 
            WHERE (BillingLatitude != NULL OR BillingLongitude != NULL) 
            AND (RecordType.Name = 'Schedule Assist' 
                 OR RecordType.Name = 'Registration' 
                 OR RecordType.Name = 'Appointment') 
            AND IsClosed__c = false
            ORDER BY DISTANCE(BillingAddress, GEOLOCATION(:dLat, :dLong), 'mi') 
            LIMIT 5 OFFSET :offset
        ];
        return lstGeoAcc;
    }
    
}