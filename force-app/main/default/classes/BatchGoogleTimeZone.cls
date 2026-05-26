public class BatchGoogleTimeZone implements Database.Batchable<sObject>,Database.AllowsCallouts{

    //apex representation of JSON
    Class TZ_Data {
        Double dstOffset =0;
        Double rawOffset =0;
        String status='';
        String timeZoneName = '';
    }

    public static Database.QueryLocator start(Database.BatchableContext bc){
        Id rtScheduleAssist = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Id rtAppointment = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Appointment').getRecordTypeId();
        Id rtRegistration = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Registration').getRecordTypeId();  
        Id rtPartnership = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partnership').getRecordTypeId();  
        Id rtAffiliations = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliations').getRecordTypeId();  
        Id rtDDSPractice = Schema.SObjectType.Account.getRecordTypeInfosByName().get('DDS Practice').getRecordTypeId();  

        String query = 'SELECT Id,billinglatitude,billinglongitude,Time_Unix__c,Time_DSTOffset__c,Time_UTCOffset__c,Time_Zone__c FROM Account '
        + 'WHERE (RecordTypeId=: rtScheduleAssist OR RecordTypeId =: rtAppointment ' 
        + 'OR RecordTypeId =: rtRegistration OR RecordTypeId =: rtPartnership OR RecordTypeId =: rtAffiliations OR RecordTypeId =: rtDDSPractice )';
        
        return Database.getQueryLocator(query);
    }

    public static void execute(Database.BatchableContext bc, List<Account> lstAccount){
        String response; 
        for(Account a:lstAccount) {            
            /*a.Time_UTCOffset__c = 0;
            a.Time_DSTOffset__c = 0;
            a.Time_Zone__c = '';*/
            if(a.BillingLatitude > 0) {
                response = callGoogleAPI(a).getBody();
                TZ_data data = (TZ_data) JSON.deserialize(response, TZ_data.class);
                if(data.rawOffset != Null && data.dstOffset != Null){
                    a.Time_UTCOffset__c = data.rawOffset;
                    a.Time_DSTOffset__c = data.dstOffset;
                    a.Time_Zone__c = data.timeZoneName;    
                }
            }
            
        }
        Database.SaveResult[] srList = Database.update(lstAccount,false);        
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {           
                for(Database.Error objErr : sr.getErrors()) {
                  System.debug('The following error has occurred while updating practice time zone:');                                    
                  System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());                 
               }
            }
         }
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

    public static void finish(Database.BatchableContext bc){
    }
    
}