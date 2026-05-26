@isTest
global class ValidatorTestHttpMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        string strEndPoint = req.getEndpoint();
        system.debug(strEndPoint);
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        
        if(strEndPOint.contains('entries')) {
            res.setBody('{ "data": [ { "index": "0", "inputData": "batman@gmail.com", "completedOn": "2019-07-31T10:49:20.5957669Z", "emailAddress": "batman@gmail.com" ,"status": "Success", "classification": "Undeliverable" } ] }');
        } else {
            res.setBody('{"overview":{"id":"142a9867-0e7d-47f9-953e-f834909281bd","submittedOn":"2022-05-12T17:43:01.228008Z","completedOn":"2022-05-12T17:43:01.4238652Z"}}');
        }            return res;
        
    }
    
}