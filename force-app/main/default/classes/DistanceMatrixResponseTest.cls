@isTest
public class DistanceMatrixResponseTest {
    @isTest
    static void testFromJSON() {
        // Sample JSON response (mocked)
        String jsonResponse = '{"destinationAddresses":["123 Main St"], "originAddresses":["456 Elm St"], "rows":[{"elements":[{"distance":{"text":"5 km","value":5000}, "duration":{"text":"10 mins","value":600}, "status":"OK"}]}], "status":"OK"}';
        
        // Deserialize
        DistanceMatrixResponse response = DistanceMatrixResponse.fromJSON(jsonResponse);
        
        // Assertions
        System.assertNotEquals(response, null, 'Response should not be null');
        System.assertEquals(response.status, 'OK', 'Status should be OK');
        
        System.assertEquals(response.destinationAddresses.size(), 1, 'Should have one destination address');
        System.assertEquals(response.destinationAddresses[0], '123 Main St', 'Destination address should match');

        System.assertEquals(response.originAddresses.size(), 1, 'Should have one origin address');
        System.assertEquals(response.originAddresses[0], '456 Elm St', 'Origin address should match');

        System.assertEquals(response.rows.size(), 1, 'Should have one row');
        System.assertEquals(response.rows[0].elements.size(), 1, 'Should have one element in row');

        DistanceMatrixResponse.Element element = response.rows[0].elements[0];
        System.assertNotEquals(element, null, 'Element should not be null');

        System.assertEquals(element.status, 'OK', 'Element status should be OK');

        System.assertNotEquals(element.distance, null, 'Distance should not be null');
        System.assertEquals(element.distance.text, '5 km', 'Distance text should match');
        System.assertEquals(element.distance.value, 5000, 'Distance value should match');

        System.assertNotEquals(element.duration, null, 'Duration should not be null');
        System.assertEquals(element.duration.text, '10 mins', 'Duration text should match');
        System.assertEquals(element.duration.value, 600, 'Duration value should match');
    }
}