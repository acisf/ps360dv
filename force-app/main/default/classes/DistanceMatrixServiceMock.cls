@IsTest
public class DistanceMatrixServiceMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setStatus('OK');
        
        if (request.getEndpoint().contains('geocode')) {
            // Mock response for Google Geocoding API
            String responseBody = '{"results": ['+
                '  {"geometry": {'+
                '    "location": {'+
                '      "lat": 33.4484,'+
                '      "lng": -112.0740'+
                '    }'+
                '  }}'+
                '],"status": "OK"}';
            response.setBody(responseBody);
            
        } else if (request.getEndpoint().contains('distancematrix')) {
            String responseBody = '{"destination_addresses": ["Destination 1", "Destination 2", "Destination 3"],'+
                '"origin_addresses": ["Origin"],'+
                '"rows": ['+
                '  {"elements": ['+
                '    {"status": "OK", "distance": {"text": "100 mi", "value": 160934},'+
                '     "duration": {"text": "1 hour 40 mins", "value": 6000}},'+
                '    {"status": "OK", "distance": {"text": "200 mi", "value": 321869},'+
                '     "duration": {"text": "3 hours 20 mins", "value": 12000}},'+
                '    {"status": "OK", "distance": {"text": "300 mi", "value": 482803},'+
                '     "duration": {"text": "5 hours", "value": 18000}}'+
                '  ]}'+
                ']}';
            response.setBody(responseBody);
            
        } else {
            // Fallback for any unexpected callout
            response.setStatusCode(400);
            response.setBody('{"error": "Unexpected endpoint: ' + request.getEndpoint() + '"}');
        }
        
        return response;
    }
}