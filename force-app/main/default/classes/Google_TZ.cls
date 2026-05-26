public class Google_TZ {

     //apex representation of JSON
    Class TZ_Data {
        Double dstOffset =0;
        Double rawOffset =0;
        String status='';
        String timeZoneName = '';
    }
    
    //make sure we have all needed fields
    public static List<Account> getAccounts(Set<Id> accounts) {
        
        List<Account> lstAccounts = new List<Account>();
        lstAccounts=[SELECT id,billinglatitude,billinglongitude,Time_Unix__c,
                            Time_DSTOffset__c,Time_UTCOffset__c,Time_Zone__c
                     FROM account
                     WHERE id IN: accounts];
        return lstAccounts;
    }
    
    //this method is invoked when a record is inserted into LocalTimeQueue__c
	@InvocableMethod
    public static void updateAccountTimeZoneDta(List<Id> AccountIds) {
        Set<Id> accounts = new Set<Id>();
        
        for(Id accountid:accountids) {
            accounts.add(accountid);
        }
        getTimeZoneData(accounts);
     
    }
    
    //gets time zone data for a set of accounts
    @future(callout=true)
    public static void getTimeZoneData(Set<Id> accounts) {
        String response;    
        List<Account> lstAccounts = getAccounts(accounts);
        for(Account a:lstAccounts) {
            a.Time_UTCOffset__c = 0;
            a.Time_DSTOffset__c = 0;
            a.Time_Zone__c = '';
            if(a.BillingLatitude > 0) {
                response = callGoogleAPI(a).getBody();
                TZ_data data = (TZ_data) JSON.deserialize(response, TZ_data.class);
                a.Time_UTCOffset__c = data.rawOffset;
                a.Time_DSTOffset__c = data.dstOffset;
                a.Time_Zone__c = data.timeZoneName;    
            }
        }
        update lstAccounts;
        
        LocalTimeQueue__c[] queue = [SELECT id FROM LocalTimeQueue__c WHERE AccountId__c IN:accounts];
        delete queue;
        
    }
    
    public static HttpResponse callGoogleAPI(Account a) {
        String url, googleAPIKey;
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();     
        HttpResponse res;

        googleAPIKey = 'AIzaSyBE9Lb6b1LDTa8hghBN1459nVcsZyrL1AE';
        
        //build url from formid, access token, & timestamp 
        url = 'https://maps.googleapis.com/maps/api/timezone/json?key=' + googleAPIKey;
        url += '&location=' + String.valueOf(a.BillingLatitude) + ',' + String.valueOf(a.BillingLongitude);
        url += '&timestamp=' + String.valueOf(a.Time_Unix__c); 
        
        //call the Google endpoint
        system.debug(url);
        req.setEndpoint(url);
        req.setmethod('GET');
        res=http.send(req);
        system.debug(res.getBody());
        return res;        
    }
}