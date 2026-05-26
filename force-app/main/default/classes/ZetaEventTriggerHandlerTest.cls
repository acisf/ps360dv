@isTest
public class ZetaEventTriggerHandlerTest {

 static testmethod void runTest() {
        Zeta_Event__c zEvent = new Zeta_Event__c();
        zevent.JSON__c = '{"user_id":"4779842","event_type":"new_appt","timestamp":"2021-10-23T15:31:00Z","practiceid":"20123","apptid":"154905","apptdate":"10/29/2021","appttime":"08:00:00 AM","apptdatetime":"2021-10-29T12:00:00Z"}';
        test.startTest();
        insert zEvent;
        test.stopTest();
        
        zEvent  = [select id, user_id__c from Zeta_Event__c];
        system.assert(zEvent.user_id__c == '4779842');
    }
}