@IsTest
public class DistanceMatrixCityStateServiceTest {
    
    @TestSetup
    static void setupTestData() {
        Id scheduleAssistRTId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Schedule_Assist').getRecordTypeId();
        
        insert new List<Account>{
            new Account(
                Name             = 'Practice One',
                RecordTypeId     = scheduleAssistRTId,
                BillingLatitude  = 33.4484,
                BillingLongitude = -112.0740,
                IsClosed__c      = false
            ),
                new Account(
                    Name             = 'Practice Two',
                    RecordTypeId     = scheduleAssistRTId,
                    BillingLatitude  = 33.5484,
                    BillingLongitude = -112.1740,
                    IsClosed__c      = false
                ),
                new Account(
                    Name             = 'Practice Three',
                    RecordTypeId     = scheduleAssistRTId,
                    BillingLatitude  = 33.6484,
                    BillingLongitude = -112.2740,
                    IsClosed__c      = false
                )
                };
                    }
    
    @IsTest
    static void testFindNearestPractices_happyPath() {
        Test.setMock(HttpCalloutMock.class, new DistanceMatrixServiceMock());
        
        DistanceMatrixCityStateService.FindNearestRequest req =
            new DistanceMatrixCityStateService.FindNearestRequest();
        req.city  = 'Phoenix';
        req.state = 'AZ';
        
        Test.startTest();
        List<DistanceMatrixCityStateService.FindNearestResult> results =
            DistanceMatrixCityStateService.findNearestPractices(
                new List<DistanceMatrixCityStateService.FindNearestRequest>{ req }
            );
        Test.stopTest();
        
        System.debug('ERROR MESSAGE: ' + results[0].errorMessage);
        System.debug('PRACTICE ID 1: ' + results[0].practiceId1);
        System.debug('PRACTICE NAME 1: ' + results[0].practiceName1);
        
        Assert.isNull(results[0].errorMessage);
    }
    
    @IsTest
    static void testFindNearestPractices_geocodeReturnsNoResults() {
        Test.setMock(HttpCalloutMock.class, new EmptyGeocodeResponseMock());
        
        DistanceMatrixCityStateService.FindNearestRequest req =
            new DistanceMatrixCityStateService.FindNearestRequest();
        req.city  = 'Nowhere';
        req.state = 'XX';
        
        Test.startTest();
        List<DistanceMatrixCityStateService.FindNearestResult> results =
            DistanceMatrixCityStateService.findNearestPractices(
                new List<DistanceMatrixCityStateService.FindNearestRequest>{ req }
            );
        Test.stopTest();
        
        Assert.isTrue(results[0].errorMessage.contains('Location not found'));
        Assert.isNull(results[0].practiceId1);
    }
    
    @IsTest
    static void testFindNearestPractices_noAccountsFound() {
        Test.setMock(HttpCalloutMock.class, new DistanceMatrixServiceMock());
        delete [SELECT Id FROM Account];
        
        DistanceMatrixCityStateService.FindNearestRequest req =
            new DistanceMatrixCityStateService.FindNearestRequest();
        req.city  = 'Phoenix';
        req.state = 'AZ';
        
        Test.startTest();
        List<DistanceMatrixCityStateService.FindNearestResult> results =
            DistanceMatrixCityStateService.findNearestPractices(
                new List<DistanceMatrixCityStateService.FindNearestRequest>{ req }
            );
        Test.stopTest();
        
        Assert.isTrue(results[0].errorMessage.contains('No open practices found'));
        Assert.isNull(results[0].practiceId1);
    }
    
    private class EmptyGeocodeResponseMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"results": [], "status": "ZERO_RESULTS"}');
            return response;
        }
    }
}