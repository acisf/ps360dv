@isTest
private class BatchCallCenterSummaryTest {
    
    @isTest
    static void testBatchCallCenterKPI() {
        Date testDate = Date.today().addDays(-1); // simulate yesterday's KPI
        
        // Create test NVM_Call_Summary__c records for TotalAbandoned and TotalAnswered
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = new List<NVMStatsSF__NVM_Call_Summary__c>{
            new NVMStatsSF__NVM_Call_Summary__c(
                NVMStatsSF__CallTime__c = DateTime.newInstance(testDate, Time.newInstance(10, 0, 0, 0))
            ),
                new NVMStatsSF__NVM_Call_Summary__c(
                    NVMStatsSF__CallTime__c = DateTime.newInstance(testDate, Time.newInstance(11, 0, 0, 0))  
                )
                };
                    insert callSummaries;
        
        
        Test.startTest();
        // Simulate batchable context
        BatchCallCenterSummary batch = new BatchCallCenterSummary(testDate);
        Call_Center_Summary__c cs = new Call_Center_Summary__c();
        batch.setSummaryValue(cs,'TotalAbandoned',0);
        batch.setSummaryValue(cs,'TotalAnswered',0);
        batch.setSummaryValue(cs,'TotalAnsweredInSVL',0);
        batch.setSummaryValue(cs,'TotalAnswerTime',0);
        batch.setSummaryValue(cs,'TotalAppointments',0);
        batch.setSummaryValue(cs,'TotalClosed',0);
        batch.setSummaryValue(cs,'TotalDispositionCount',0);
        batch.setSummaryValue(cs,'TotalInbound',0);
        batch.setSummaryValue(cs,'TotalOffered',0);
        batch.setSummaryValue(cs,'TotalQuestion1',0);
        batch.setSummaryValue(cs,'TotalResolved',0);
        batch.setSummaryValue(cs,'TotalScheduledCount',0);
        batch.setSummaryValue(cs,'TotalSurveys',0);
        batch.setSummaryValue(cs,'TotalTransfers',0);
        
        
        batch.runAggregateQuery('TotalAbandoned');
        batch.runAggregateQuery('TotalAnswered');
        batch.runAggregateQuery('TotalAnsweredInSVL');
        batch.runAggregateQuery('TotalAnswerTime');
        batch.runAggregateQuery('TotalAppointments');
        batch.runAggregateQuery('TotalClosed');
        batch.runAggregateQuery('TotalDispositionCount');
        batch.runAggregateQuery('TotalInbound');
        batch.runAggregateQuery('TotalOffered');
        batch.runAggregateQuery('TotalQuestion1');
        batch.runAggregateQuery('TotalResolved');
        batch.runAggregateQuery('TotalScheduledCount');
        batch.runAggregateQuery('TotalSurveys');
        batch.runAggregateQuery('TotalTransfers');
        
        
        ID batchId = Database.executeBatch(batch, 1);
        Test.stopTest();
        
        // Verify that the KPI record is created and populated
        List<Call_Center_Summary__c> summaryRecords = [
            SELECT KPI_Date__c, TotalAbandoned__c, TotalAnswered__c
            FROM Call_Center_Summary__c
            WHERE KPI_Date__c = :testDate
        ];
        
        System.assertEquals(1, summaryRecords.size()); 
    }
}