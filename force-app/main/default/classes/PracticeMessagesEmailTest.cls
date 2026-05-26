@isTest
public class PracticeMessagesEmailTest {
    
    @isTest static void testCallout() {
        
        Test.startTest();         
        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.GENERIC));        
        HttpResponse res = PracticeMessagesEmail.getActivePracticesReport();
        String contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'text/plain');
        System.assertEquals(200, res.getStatusCode());
        
        
        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.GENERIC));       
        res = PracticeMessagesEmail.getSchedulingRequirements();
        contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'text/plain');
        System.assertEquals(200, res.getStatusCode());
        
        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.GENERIC));       
        res = PracticeMessagesEmail.getPracticeAttributes();
        contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'text/plain');
        System.assertEquals(200, res.getStatusCode());
        
        PracticeMessagesEmail.sendEmail(); 
         Test.stopTest(); 
        
        Integer invocations = Limits.getEmailInvocations();
        System.assertEquals(0,invocations);
       
    }
}