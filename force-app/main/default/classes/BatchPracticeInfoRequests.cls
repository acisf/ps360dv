global class BatchPracticeInfoRequests  implements Database.Batchable<SObject>, Database.Stateful {
    
    //Query all Practice_Info_Request__c records created today
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Case__c, Practice__c, Quantity__c, CreatedDate, Case__r.ContactId FROM Practice_Info_Request__c WHERE CreatedDate = TODAY ORDER BY Case__c, Practice__c, Case__r.ContactId, CreatedDate';
        return Database.getQueryLocator(query);
    }

    //Process each batch of records
    global void execute(Database.BatchableContext BC, List<Practice_Info_Request__c> scope) {
        Map<String, Practice_Info_Request__c> primaryRequests = new Map<String, Practice_Info_Request__c>();
        List<Practice_Info_Request__c> recordsToUpdate = new List<Practice_Info_Request__c>();

        for (Practice_Info_Request__c request : scope) {
            String key = request.Practice__c + '-' + request.Case__r.ContactId;

            if (!primaryRequests.containsKey(key)) {
                primaryRequests.put(key, request);
                System.debug('Primary request: ' + request);
            } else {
                 System.debug('Duplicate request: ' + request);
                Practice_Info_Request__c primaryRequest = primaryRequests.get(key);
                primaryRequest.Quantity__c += request.Quantity__c; // Combine quantities
                request.Quantity__c = 0; // Set the quantity of the duplicate to 0
                recordsToUpdate.add(request);
            }
        }

        // Add the primary records with updated quantities to the list
        recordsToUpdate.addAll(primaryRequests.values());

        // Update all records in a single operation
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}