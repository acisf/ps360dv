@isTest
private class CallCenterKPIJobTest {

    @isTest
    static void testRunMethod() {
        Date startDate = Date.today().addDays(-6);
        Date endDate = Date.today();

        // Create sample summary records
        List<Call_Center_Summary__c> summaries = new List<Call_Center_Summary__c>();
        for (Integer i = 0; i < 3; i++) {
            summaries.add(new Call_Center_Summary__c(
                KPI_Date__c = startDate.addDays(i),
                Company__c = 'Test Company',
                TotalAbandoned__c = 2,
                TotalAnswered__c = 8,
                TotalAnsweredInSVL__c = 6,
                TotalAnswerTime__c = 40,
                TotalAppointments__c = 3,
                TotalClosed__c = 4,
                TotalDispositionCount__c = 5,
                TotalInbound__c = 9,
                TotalOffered__c = 10,
                TotalQuestion1__c = 12,
                TotalResolved__c = 2,
                TotalScheduledCount__c = 3,
                TotalSurveys__c = 4,
                TotalTransfers__c = 1
            ));
        }
        insert summaries;

        Test.startTest();
        CallCenterKPIJob.run(startDate, endDate);
        Test.stopTest();

        // Verify the KPI record was inserted
        List<Call_Center_KPI__c> kpis = [SELECT Id, Start_Date__c, End_Date__c, Calls_Answered__c FROM Call_Center_KPI__c];
        System.assertEquals(1, kpis.size(), 'A single KPI record should be inserted');
        System.assertEquals(startDate, kpis[0].Start_Date__c);
        System.assertEquals(endDate, kpis[0].End_Date__c);
        System.assertEquals(24, kpis[0].Calls_Answered__c); // 3 records × 8 answered each
    }

    @isTest
    static void testRunWithInvalidDates() {
        // Null dates
        try {
            CallCenterKPIJob.run(null, null);
            System.assert(false, 'Expected exception for null dates');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required'));
        }

        // Start date after end date
        try {
            CallCenterKPIJob.run(Date.today(), Date.today().addDays(-1));
            System.assert(false, 'Expected exception for startDate > endDate');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('on or before'));
        }
    }
}