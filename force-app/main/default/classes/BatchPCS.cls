global class BatchPCS implements Database.Batchable<SObject> {
    
    // Step 1: Define the query to pull all NVM_PCS__c records created this month where Vonage_Call_Summary__c is null
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Call_Object_Identifier__c ' +
                       'FROM NVM_PCS__c ' +
                       'WHERE CreatedDate = TODAY ' +
                       'AND Vonage_Call_Summary__c = null';
        return Database.getQueryLocator(query);
    }

    // Step 2: Extract Call_Object_Identifier__c into a Set and process the records in batches
    global void execute(Database.BatchableContext bc, List<NVM_PCS__c> pcsRecords) {
        Set<String> callObjectIds = new Set<String>();
        
        // Step 2: Collect Call_Object_Identifier__c values
        for (NVM_PCS__c pcs : pcsRecords) {
            if (pcs.Call_Object_Identifier__c != null) {
                callObjectIds.add(pcs.Call_Object_Identifier__c);
            }
        }
        
        // Step 3: Lookup matching NVM_Call_Summary__c records based on NVMStatsSF__CallGuid__c
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = [SELECT Id, NVMStatsSF__CallGuid__c 
                                                               FROM NVMStatsSF__NVM_Call_Summary__c 
                                                               WHERE NVMStatsSF__CallGuid__c IN :callObjectIds];
        
        // Step 4: Create a Map for easier lookup of CallGuid to Call Summary Id
        Map<String, Id> callGuidToSummaryIdMap = new Map<String, Id>();
        for (NVMStatsSF__NVM_Call_Summary__c callSummary : callSummaries) {
            callGuidToSummaryIdMap.put(callSummary.NVMStatsSF__CallGuid__c, callSummary.Id);
        }
        
        // Step 5: Loop through NVM_PCS__c records and update Vonage_Call_Summary__c with matching Call Summary Id
        for (NVM_PCS__c pcs : pcsRecords) {
            if (callGuidToSummaryIdMap.containsKey(pcs.Call_Object_Identifier__c)) {
                pcs.Vonage_Call_Summary__c = callGuidToSummaryIdMap.get(pcs.Call_Object_Identifier__c);
            }
        }
        
        // Step 6: Update the records
        if (!pcsRecords.isEmpty()) {
            update pcsRecords;
        }
    }

    // Step 7: Optional finish method
    global void finish(Database.BatchableContext bc) {
        // Any post-processing logic after the batch is complete
    }
}