//🐙

@isTest
global class Mocktopus implements HttpCalloutMock {
    
    public enum MockScenario {
            GENERIC,
            FACEBOOK,
            GOOGLE,
            VALIDATOR
            }
    
    private MockScenario scenario;
    
    // Constructor to set the desired scenario
    public Mocktopus(MockScenario scenario) {
        this.scenario = scenario;
    }
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        
        switch on scenario {
            when GENERIC {
                res.setHeader('Content-Type', 'text/plain');
                res.setBody('test');
            }
            when FACEBOOK {
                res.setHeader('Content-Type', 'application/json');
                res.setBody(getFacebookMockBody());
            }
            when GOOGLE {
                res.setHeader('Content-Type', 'application/json');
                res.setBody(getGoogleMockBody());
            }
            when VALIDATOR {
                string strEndPoint = req.getEndpoint();
                res.setHeader('Content-Type', 'application/json');
                if(strEndPoint.contains('entries')) 
                    res.setBody(getValidatorMockBody());          
                else 
                    res.setBody(getValidatorSubmitJobMockBody());
            }
        }
        
        return res;
    }
    
    private static String getFacebookMockBody() {
        return '{ "data": [ ' +
            '{ "created_time": "2019-11-08T06:30:00+0000", "ad_name": "my_adname_01002", "id": "496445134282879", "field_data": [ { "name": "full_name", "values": [ "John Doe" ] }, { "name": "email", "values": [ "john.doe@example.com" ] } ] },' +
            '{ "created_time": "2019-11-08T07:30:00+0000", "ad_name": "my_adname_1002_", "id": "126335134282879", "field_data": [ { "name": "full_name", "values": [ "Jane Doe" ] }, { "name": "email", "values": [ "jane.doe@example.com" ] } ] },' +
            '{"created_time":"2022-08-17T16:15:08+0000","id":"601970174980907","field_data":[{"name":"Campaign","values":["CareCredit"]},{"name":"Type","values":["LeadGen"]},{"name":"Source","values":["Messenger"]},{"name":"are_you_currently_missing_teeth?","values":["i\'m_missing_one_tooth."]},{"name":"do_you_currently_use_any_of_the_following_treatments?","values":["crowns/bridges"]},{"name":"what_timeframe_are_you_seeking_to_receive_treatment_from_any_dental_discomfort?","values":["urgent,_now!"]},{"name":"what_has_been_holding_you_back_from_receiving_treatment?","values":["fear"]},{"name":"have_you_received_a_treatment_plan_from_another_dentist_recently?","values":["no"]},{"name":"are_you_interested_in_financing_options?_if_so,_how_would_you_rate_your_credit_worthiness?","values":["good/great"]},{"name":"full_name","values":["Rebecca Keenan"]},{"name":"what\'s_the_best_number_to_call_or_text?","values":["+13127854141"]},{"name":"what_is_your_email_address_(we_promise_we_won\'t_sell_or_spam_your_email)?","values":["rebeccazaiter\u0040gmail.com"]},{"name":"zip_code","values":["27606"]},{"name":"inbox_url","values":["https://www.facebook.com/AffordableDenturesImplants/inbox/100003974882948/"]}]}' +
            ']}';
    }
    
    private static String getGoogleMockBody() {
        return '{"dstOffset":3600,"rawOffset":-18000,"status":"OK","timeZoneId":"America/New_York","timeZoneName":"Eastern Daylight Time"}';
    }
    
    private static String getValidatorMockBody() {
        return '{ "data": [ { "index": "0", "inputData": "batman@gmail.com", "completedOn": "2019-07-31T10:49:20.5957669Z", "emailAddress": "batman@gmail.com" ,"status": "Success", "classification": "Undeliverable" } ] }';
    }
    
    private static String getValidatorSubmitJobMockBody() {
        return '{"overview":{"id":"142a9867-0e7d-47f9-953e-f834909281bd","submittedOn":"2022-05-12T17:43:01.228008Z","completedOn":"2022-05-12T17:43:01.4238652Z"}}';
    }
}