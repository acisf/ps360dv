global class BatchProcessTmpCases implements Database.Batchable<SObject> {

    // Start method to query tmp__c records
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, contact__c, practice__c, phone__c, Offer__c, first__c, last__c, locationid__c FROM tmp__c WHERE contact__c != null AND Case_Created__c = false';
        return Database.getQueryLocator(query);
    }
    
    // Execute method to process each batch
    global void execute(Database.BatchableContext BC, List<tmp__c> scope) {
        List<Case> casesToCreate = new List<Case>();
        List<tmp__c> tmpToUpdate = new List<tmp__c>();
        List<Group> lstQ = new List<Group>();
        Id queueid = UserInfo.getUserId();
        
        lstQ = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Outbound_Campaign' LIMIT 1];
        
        for(Group g:lstQ) {
            queueid = g.id;
        }
               
      
        // Create cases for each tmp__c record
        for (tmp__c tmpRecord : scope) {
            Case newCase = new Case(
                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Outbound Campaign').getRecordTypeId(),
                OwnerId = queueid,
                Subject = 'Outbound Campaign - ' + tmpRecord.Offer__c,
                ContactId = tmpRecord.contact__c,
                AccountId = tmpRecord.practice__c,
                SuppliedPhone = tmpRecord.phone__c,
                Offer__c = tmpRecord.offer__c,
                Origin = 'Campaign',
                Description = 'First: ' + tmpRecord.first__c + '\n' +
                              'Last: ' + tmpRecord.last__c + '\n' +
                              'Location ID: ' + tmpRecord.locationid__c + '\n' +
                              'Phone: ' + tmpRecord.phone__c + '\n' +
                              'Offer: ' + tmpRecord.Offer__c
            );
            casesToCreate.add(newCase);
            tmpRecord.Case_Created__c = true;
            tmpToUpdate.add(tmpRecord);
        }
        
        // Insert new cases
        if (!casesToCreate.isEmpty()) {
            insert casesToCreate;
        }
        
        update tmpToUpdate;
    }
    
    // Finish method (optional)
    global void finish(Database.BatchableContext BC) {
    }
}