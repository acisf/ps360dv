@isTest
public class BatchGoogleTimeZoneTest {

    @isTest
    public static void testSetPracticeTimeZone() {
        Id rtScheduleAssist = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Integer i;
        Account acc = new Account();         
        acc.Name = 'Test Practice';
        acc.RecordTypeId = rtScheduleAssist;
        acc.location_id__c = '01001';
        acc.isClosed__c = false;
        acc.billinglatitude = 35.8097;
        acc.billinglongitude = -78.8811;
        acc.Time_UTCOffset__c = 0;
        acc.Time_DSTOffset__c = 0;
        insert acc;      

        Test.setMock(HttpCalloutMock.class, new Mocktopus(Mocktopus.MockScenario.GOOGLE));
        Test.startTest();
      
        BatchGoogleTimeZone btz = new BatchGoogleTimeZone();
        Database.executeBatch(btz);
        Test.stopTest();

        Account a = [Select Id,billinglatitude,billinglongitude,Time_Unix__c,Time_DSTOffset__c,Time_UTCOffset__c,Time_Zone__c 
                    FROM Account where id = :acc.id];
        System.assertEquals(-18000,a.Time_UTCOffset__c);
        System.assertEquals(3600,a.Time_DSTOffset__c);
        System.assertEquals('Eastern Daylight Time',a.Time_Zone__c);
    }
}