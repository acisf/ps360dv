@IsTest
private class BatchOaiSurveyTest {

    @IsTest
    static void testBatchOaiSurvey() {

        // Step 1: Create NVM Call Summary records
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = new List<NVMStatsSF__NVM_Call_Summary__c>();
        for (Integer i = 0; i < 5; i++) {
            callSummaries.add(new NVMStatsSF__NVM_Call_Summary__c(
                NVMStatsSF__CallGuid__c = 'GUID_' + i
            ));
        }
        insert callSummaries;

        // Step 2: Create OAI_Survey__c records for GUID match
        List<OAI_Survey__c> surveysGuid = new List<OAI_Survey__c>();
        for (Integer i = 0; i < 3; i++) {
            surveysGuid.add(new OAI_Survey__c(
                Call_GUID__c = 'GUID_' + i
            ));
        }


        insert surveysGuid;

        // Step 4: Run the batch
        Test.startTest();
            BatchOaiSurvey batch = new BatchOaiSurvey();
            Database.executeBatch(batch);
        Test.stopTest();

        // Step 5: Verify updates
        List<OAI_Survey__c> updatedSurveys = [SELECT Id, Vonage_Call_Summary__c, Call_GUID__c, Task_ID__c FROM OAI_Survey__c];

        Map<String, Id> guidToSummary = new Map<String, Id>();
        for (NVMStatsSF__NVM_Call_Summary__c cs : callSummaries) {
            guidToSummary.put(cs.NVMStatsSF__CallGuid__c, cs.Id);
        }

        for (OAI_Survey__c survey : updatedSurveys) {
            if (survey.Call_GUID__c != null) {
                // Should match by GUID
                System.assertEquals(guidToSummary.get(survey.Call_GUID__c), survey.Vonage_Call_Summary__c);
            } else { 
                System.assertEquals(null, survey.Vonage_Call_Summary__c);
            }
        }
    }
}