public class DistanceMatrixCityStateService {

    private static final String API_KEY = 'AIzaSyBE9Lb6b1LDTa8hghBN1459nVcsZyrL1AE';

    // ── Request ──────────────────────────────────────────────────────────────

    public class FindNearestRequest {
        @InvocableVariable(label='City' required=true)
        public String city;

        @InvocableVariable(label='State' required=true)
        public String state;
    }

    // ── Result ───────────────────────────────────────────────────────────────

    public class FindNearestResult {
        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Practice Id 1')
        public String practiceId1;
        @InvocableVariable(label='Practice Name 1')
        public String practiceName1;

        @InvocableVariable(label='Practice Id 2')
        public String practiceId2;
        @InvocableVariable(label='Practice Name 2')
        public String practiceName2;

        @InvocableVariable(label='Practice Id 3')
        public String practiceId3;
        @InvocableVariable(label='Practice Name 3')
        public String practiceName3;
    }

    // ── Invocable Entry Point ─────────────────────────────────────────────────

    @InvocableMethod(
        label       = 'Find Nearest Practices by City and State'
        description = 'Given a city and state, geocodes the location and returns the 3 nearest open dental practices. Use when the patient provides a city and state but not a zip code.'
        category    = 'Account'
    )
    public static List<FindNearestResult> findNearestPractices(List<FindNearestRequest> requests) {

        List<FindNearestResult> results = new List<FindNearestResult>();

        for (FindNearestRequest req : requests) {
            FindNearestResult res = new FindNearestResult();
            try {
                Zip_Code__c location = geocodeCityState(req.city, req.state);
                if (location == null) {
                    res.errorMessage = 'Location not found for ' + req.city + ', ' + req.state + '. Please verify and try again.';
                    results.add(res);
                    continue;
                }

                List<Account> lstAccounts = getAccountsNearLocation(location);
                if (lstAccounts.isEmpty()) {
                    res.errorMessage = 'No open practices found near ' + req.city + ', ' + req.state + '.';
                    results.add(res);
                    continue;
                }

                String   origin       = location.latitude__c + ',' + location.longitude__c;
                String[] destinations = buildDestinations(lstAccounts);
                DistanceMatrixResponse dmr = getDistancesFromGoogle(origin, destinations);

                List<NearestAccount> nearest = buildNearestList(lstAccounts, dmr);

                if (nearest.size() > 0) {
                    res.practiceId1   = nearest[0].recordid;
                    res.practiceName1 = nearest[0].Name;
                }
                if (nearest.size() > 1) {
                    res.practiceId2   = nearest[1].recordid;
                    res.practiceName2 = nearest[1].Name;
                }
                if (nearest.size() > 2) {
                    res.practiceId3   = nearest[2].recordid;
                    res.practiceName3 = nearest[2].Name;
                }

            } catch (Exception e) {
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    // ── Geocoding ─────────────────────────────────────────────────────────────

    public static Zip_Code__c geocodeCityState(String city, String state) {
        String address = EncodingUtil.urlEncode(city + ', ' + state, 'UTF-8');
        String url     = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + address + '&key=' + API_KEY;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');

        HttpResponse response = http.send(request);
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        List<Object> results = (List<Object>) body.get('results');
        if (results == null || results.isEmpty()) return null;

        Map<String, Object> geometry = (Map<String, Object>)
            ((Map<String, Object>) results[0]).get('geometry');
        Map<String, Object> location = (Map<String, Object>) geometry.get('location');

        Zip_Code__c zipCode     = new Zip_Code__c();
        zipCode.latitude__c     = (Decimal) location.get('lat');
        zipCode.longitude__c    = (Decimal) location.get('lng');
        return zipCode;
    }

    // ── Account Query ─────────────────────────────────────────────────────────

    public static List<Account> getAccountsNearLocation(Zip_Code__c location) {
        return [
            SELECT Id, Name, RecordType.Name, BillingLatitude, BillingLongitude,
                   Service_Codes__c, Insurance_Accepted__c
            FROM Account
            WHERE (RecordType.Name = 'Schedule Assist' OR
                   RecordType.Name = 'Registration'    OR
                   RecordType.Name = 'Appointment')
              AND IsClosed__c       = false
              AND BillingLatitude  != NULL
              AND BillingLongitude != NULL
            ORDER BY DISTANCE(BillingAddress, GEOLOCATION(:location.latitude__c, :location.longitude__c), 'mi')
            LIMIT 25
        ];
    }

    // ── Build Destinations Array ──────────────────────────────────────────────

    public static String[] buildDestinations(List<Account> lstAccounts) {
        String[] destinations = new String[lstAccounts.size()];
        for (Integer i = 0; i < lstAccounts.size(); i++) {
            destinations[i] = lstAccounts[i].BillingLatitude + ',' + lstAccounts[i].BillingLongitude;
        }
        return destinations;
    }

    // ── Google Distance Matrix Callout ────────────────────────────────────────

    public static DistanceMatrixResponse getDistancesFromGoogle(String origin, String[] destinations) {
        String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
            + 'origins='      + origin
            + '&destinations=' + String.join(destinations, '|')
            + '&units=imperial&mode=driving'
            + '&key='         + API_KEY;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');

        HttpResponse response = http.send(request);
        return DistanceMatrixResponse.fromJSON(response.getBody());
    }

    // ── Build + Sort NearestAccount List ─────────────────────────────────────

    public static List<NearestAccount> buildNearestList(List<Account> lstAccounts, DistanceMatrixResponse dmr) {
        List<NearestAccount> nearest = new List<NearestAccount>();
        Integer i = 0;
        for (DistanceMatrixResponse.Row row : dmr.rows) {
            for (DistanceMatrixResponse.Element element : row.elements) {
                if (element.status == 'OK') {
                    NearestAccount na = new NearestAccount();
                    na.recordid       = lstAccounts[i].Id;
                    na.Name           = lstAccounts[i].Name;
                    na.distancevalue  = element.distance.value;
                    nearest.add(na);
                }
                i++;
            }
        }
        nearest.sort();
        return nearest;
    }
}