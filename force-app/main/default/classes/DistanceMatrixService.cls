public class DistanceMatrixService {
    
    @AuraEnabled
    public static List<NearestAccount> getNearestPractices(String postalCode) {
        
        List<NearestAccount> lstNearest = new List<NearestAccount>();
        NearestAccount na;
        Integer i=0;
        
        Zip_Code__c zipCode = getZipByPostalCode(postalCode);
        if(zipCode !=null) {
            List<Account> lstAccounts = getAccountsNearZipCode(zipCode);
            String origin = buildOriginForGoogleAPI(zipCode);
            String[] destinations = buildDestinationsForGoogleAPI(lstAccounts);        
            DistanceMatrixResponse dmr = getDistancesFromGoogle(origin,destinations);
            
            System.debug(dmr.rows);         
            
            for(DistanceMatrixResponse.Row row: dmr.Rows) {
                for (DistanceMatrixResponse.Element element : row.elements) {                
                    na = new NearestAccount();
                    na.recordid = lstAccounts[i].id;
                    na.nameurl = '/lightning/r/Account/' + na.recordid + '/view';
                    na.distancetext = row.elements[i].distance.text;
                    na.distancevalue = row.elements[i].distance.value;
                    na.drivingtime = row.elements[i].duration.text; 
                    na.Name = lstAccounts[i].name;
                    na.servicecode = lstAccounts[i].Service_Codes__c;
                    na.practicetype = lstAccounts[i].RecordType.Name;
                    na.insaccepted = lstAccounts[i].Insurance_Accepted__c;
                    lstNearest.add(na);
                    i++;
                }
            }
        }
        
        return lstNearest;
    }
    
    @AuraEnabled
    public static List<NearestAccount> getPracticeDistances(String postalCode, List<Account> lstAccounts) {
        
        List<NearestAccount> lstNearest = new List<NearestAccount>();
        NearestAccount na;
        Integer i=0;
        
        Zip_Code__c zipCode = getZipByPostalCode(postalCode);
        if(zipCode !=null) {           
            String origin = buildOriginForGoogleAPI(zipCode);
            String[] destinations = buildDestinations(lstAccounts);        
            DistanceMatrixResponse dmr = getDistancesFromGoogle(origin,destinations);
            
            System.debug(dmr.rows);         
            
            for(DistanceMatrixResponse.Row row: dmr.Rows) {
                for (DistanceMatrixResponse.Element element : row.elements) {                
                    na = new NearestAccount();
                    na.recordid = lstAccounts[i].id;
                    na.nameurl = '/lightning/r/Account/' + na.recordid + '/view';
                    na.distancetext = row.elements[i].distance.text;
                    na.distancevalue = row.elements[i].distance.value;
                    na.drivingtime = row.elements[i].duration.text; 
                    na.Name = lstAccounts[i].name;
                    na.servicecode = lstAccounts[i].Service_Codes__c;
                    na.practicetype = lstAccounts[i].RecordType.Name;
                    na.insaccepted = lstAccounts[i].Insurance_Accepted__c;
                    lstNearest.add(na);
                    i++;
                }
            }
        }
        
        return lstNearest;
    }
    
    
    public static Zip_Code__c getZipByPostalCode(String zip) {
        List<Zip_Code__c> lstZipCodes;
        Zip_Code__c zipCode;               
        lstZipCodes = [Select Id, latitude__c,longitude__c
                       FROM Zip_Code__c
                       WHERE zip__c = : zip
                       LIMIT 1];
        for(Zip_Code__c z:lstZipCodes) {
            zipCode = z;
        }
        System.debug(zipCode);
        return zipCode;
    }
    
    public static List<Account> getAccountsNearZipCode(Zip_Code__c zipCode) {
        List<Account> lstAccounts;
        lstAccounts = [SELECT Id, Name, RecordType.Name, BillingLatitude,BillingLongitude,Service_Codes__c,Insurance_Accepted__c
                       FROM Account                   
                       WHERE
                       (RecordType.Name = 'Schedule Assist' OR 
                        RecordType.Name = 'Registration' OR
                        RecordType.Name = 'Appointment') AND
                       IsClosed__c = false AND
                       (BillingLatitude != NULL OR BillingLongitude != NULL)
                       ORDER BY DISTANCE(BillingAddress, GEOLOCATION(:zipCode.latitude__c, :zipCode.longitude__c), 'mi') LIMIT 5];   
        
        System.debug(lstAccounts);
        return lstAccounts;      
    }
    
    public static String buildOriginForGoogleAPI(Zip_Code__c zipCode) {
        String strOrigin = zipCode.latitude__c + ',' + zipCode.longitude__c;
        System.debug('Origin ' + strOrigin);
        return strOrigin;
    }
    
    public static String[] buildDestinationsForGoogleAPI(List<Account> lstAccounts) {
        Integer x = 0;
        String[] destinations = new String[lstAccounts.size()]; // was hardcoded new String[5]
        for (Account a : lstAccounts) {
            destinations[x] = a.BillingLatitude + ',' + a.BillingLongitude;
            x++;
        }
        return destinations;
    }
    
    public static String[] buildDestinations(list<Account> lstAccounts) {
        Integer x = 0; 
        Integer arraySize = lstAccounts.size();
        String[] destinations = new String[arraySize];
        for(Account a: lstAccounts) {
            destinations[x] = a.BillingLatitude + ',' + a.BillingLongitude;
            x++;    
        }
        System.debug(destinations);
        return destinations;
    }
    
    
    public static DistanceMatrixResponse getDistancesFromGoogle(String origin, String[] destinations) {
        String baseUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';
        String apiKey = 'AIzaSyBE9Lb6b1LDTa8hghBN1459nVcsZyrL1AE';
        String url = buildUrl(baseURL, origin, destinations,apiKey);
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        
        HttpResponse response = http.send(request);
        return DistanceMatrixResponse.fromJSON(response.getBody()) ;
    }
    
    public static String buildUrl(String baseURL, String origin, String[] destinations, String apiKey) {
        String strParams = '';
        
        Map<String, String> params = new Map<String, String>{
            'origins' => origin,
                'destinations' => String.join(destinations, '|'),
                'units' => 'imperial',
                'mode' => 'driving',
                'key' => apiKey
                };
                    
                    for (String strKey : params.keySet()) {
                        strParams += strKey + '=' + params.get(strKey) + '&';
                    }
        System.debug('URL ' + baseURl + '?' + strParams);
        return baseUrl + '?' + strParams;
    }
}