global class BatchContactCleanup implements Database.Batchable<SObject> {
    
    
    // Start method: Query for contacts meeting the criteria
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Date TARGET_DATE = Date.newInstance(2019, 11, 1);
        
        return Database.getQueryLocator([
            SELECT Id 
            FROM Contact 
            WHERE RecordType.Name IN ('Patient', 'DDS Patient')
            AND LastModifiedDate < :TARGET_DATE
            AND (LastActivityDate__c = null OR LastActivityDate__c < :TARGET_DATE)
        ]);
    }
    
    // Execute method: Process contacts in batches, gather IDs for deletion, and delete related tasks and cases
    global void execute(Database.BatchableContext bc, List<Contact> contacts) {
        
        
        Date TARGET_DATE = Date.newInstance(2019, 11, 1);
        Set<Id> contactIdsForDeletion = new Set<Id>();
        
        
        // Collect Contact IDs for deletion later
        for (Contact con : contacts) {
            contactIdsForDeletion.add(con.Id);
        }
        
        if (!contactIdsForDeletion.isEmpty()) {
            // Delete tasks associated with these contacts that meet the criteria
            List<Task> tasksToDelete = [SELECT Id FROM Task WHERE WhoId IN :contactIdsForDeletion AND LastModifiedDate < :TARGET_DATE];
            if (!tasksToDelete.isEmpty()) {
                Database.delete(tasksToDelete,false);
            }
            
            // Delete closed cases associated with these contacts that meet the criteria
            List<Case> casesToDelete = [
                SELECT Id 
                FROM Case 
                WHERE ContactId IN :contactIdsForDeletion 
                AND CreatedDate < :TARGET_DATE
            ];
            if (!casesToDelete.isEmpty()) {
                Database.delete(casesToDelete,false);
            }
            
            // Assuming 'contacts' is a list of Contact records you want to delete
            Database.DeleteResult[] deleteResults = Database.delete(contacts, false);
            
            for (Integer i = 0; i < deleteResults.size(); i++) {
                Database.DeleteResult result = deleteResults[i];
                
                if (result.isSuccess()) {
                    System.debug('Record deleted successfully: ' + contacts[i].Id);
                } else {
                    // Loop through any errors for this specific record
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Failed to delete record with Id: ' + contacts[i].Id);
                        System.debug('Error message: ' + error.getMessage());
                        System.debug('Status code: ' + error.getStatusCode());
                    }
                }
            }
            
            
            
        }
    }
    
    // Finish method: Log or finalize actions, such as contact deletion or follow-up
    global void finish(Database.BatchableContext bc) {
        
    }
}