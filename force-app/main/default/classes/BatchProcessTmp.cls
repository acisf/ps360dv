global class BatchProcessTmp implements Database.Batchable<SObject> {

    // Start method to query tmp__c records
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, contact__c, first__c, last__c, locationid__c, phone__c, practice__c, Offer__c FROM tmp__c ';
        return Database.getQueryLocator(query);
    }
    
    // Execute method to process each batch
    global void execute(Database.BatchableContext BC, List<tmp__c> scope) {
        Map<String, Account> locationToAccountMap = new Map<String, Account>();
        Map<String, Contact> contactKeyToContactMap = new Map<String, Contact>();
        List<tmp__c> tmpToUpdate = new List<tmp__c>();
        List<Contact> contactsToCreate = new List<Contact>();

        // Fetch the RecordTypeId for 'Patient'
        Id patientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
        
        // Step 1: Sanitize the data
        for (tmp__c tmpRecord : scope) {
            if (tmpRecord.locationid__c != null) {
                tmpRecord.locationid__c = tmpRecord.locationid__c.leftPad(5, '0');
            }
            if (tmpRecord.phone__c != null) {
                String sanitizedPhone = tmpRecord.phone__c.replaceAll('[^0-9]', ''); // Remove non-numeric characters
                if (sanitizedPhone.length() > 10) {
                    sanitizedPhone = sanitizedPhone.substring(sanitizedPhone.length() - 10);
                }
                tmpRecord.phone__c = sanitizedPhone;
            }
            if( !String.isEmpty(tmpRecord.first__c)){
                tmpRecord.first__c = tmpRecord.first__c.trim().tolowercase();
            }
              if( !String.isEmpty(tmpRecord.last__c)){
                tmpRecord.last__c = tmpRecord.last__c.trim().tolowercase();
            }
                
        }
        
             
        // Step 2: Query Accounts based on padded locationid__c
        Set<String> locationIds = new Set<String>();
        for (tmp__c tmpRecord : scope) {
            if (tmpRecord.locationid__c != null) {
                locationIds.add(tmpRecord.locationid__c);
            }
        }
        
        if (!locationIds.isEmpty()) {
            List<Account> accounts = [SELECT Id, Location_Id__c FROM Account WHERE Location_Id__c IN :locationIds];
            for (Account acc : accounts) {
                locationToAccountMap.put(acc.Location_Id__c, acc);
            }
        }
        
        // Step 3: Update tmp__c.practice__c with the Account.Id
        for (tmp__c tmpRecord : scope) {
            if (tmpRecord.locationid__c != null && locationToAccountMap.containsKey(tmpRecord.locationid__c)) {
                tmpRecord.practice__c = locationToAccountMap.get(tmpRecord.locationid__c).Id;
            }
        }
        
        // Step 4: Prepare to query Contacts based on tmp__c records
        Set<String> contactKeys = new Set<String>();
        for (tmp__c tmpRecord : scope) {
            if (tmpRecord.last__c != null && tmpRecord.locationid__c != null) {
                if (tmpRecord.phone__c != null) {
                    String contactKey = tmpRecord.first__c + '-' + tmpRecord.last__c + '-' + tmpRecord.phone__c + '-' + tmpRecord.locationid__c;
                    contactKeys.add(contactKey);
                }
            }
        }
        
        // Query Contacts based on prepared keys and the 'Patient' record type
        if (!contactKeys.isEmpty()) {
            List<Contact> existingContacts = [
                SELECT Id, Contact_Key__c 
                FROM Contact 
                WHERE Contact_Key__c IN :contactKeys
                AND RecordTypeId = :patientRecordTypeId
            ];
            for (Contact contact : existingContacts) {
                contactKeyToContactMap.put(contact.Contact_Key__c, contact);
            }
        }
       
        // Step 5: Update tmp__c.contact__c with the Contact.Id or prepare new Contact creation
        for (tmp__c tmpRecord : scope) {
            if (tmpRecord.first__c != null && tmpRecord.last__c != null && tmpRecord.locationid__c != null) {
                String contactKey = tmpRecord.first__c + '-' + tmpRecord.last__c + '-' + tmpRecord.phone__c + '-' + tmpRecord.locationid__c;
                
                if (contactKeyToContactMap.containsKey(contactKey)) {
                    tmpRecord.contact__c = contactKeyToContactMap.get(contactKey).Id;
                } else if (tmpRecord.contact__c == null && tmpRecord.practice__c != null && tmpRecord.phone__c != null && tmpRecord.last__c != null) {
                    Contact newContact = new Contact(
                        FirstName = tmpRecord.first__c.capitalize(),
                        LastName = tmpRecord.last__c.capitalize(),
                        AccountId = tmpRecord.practice__c,
                        MobilePhone = tmpRecord.phone__c,
                        Description = 'Created for outbound',
                        RecordTypeId = patientRecordTypeId
                    );
                    contactsToCreate.add(newContact);
                }
                tmpToUpdate.add(tmpRecord);
            }
        }
        
        // Create new Contacts
        if (!contactsToCreate.isEmpty()) {
            insert contactsToCreate;
            
            // Prepare to re-query newly created Contacts using their IDs
            Set<Id> newContactIds = new Set<Id>();
            for (Contact newContact : contactsToCreate) {
                newContactIds.add(newContact.Id);
            }
            
            // Re-query the newly created contacts to get the Contact_Key__c and their Ids
            List<Contact> newlyCreatedContacts = [
                SELECT Id, Contact_Key__c 
                FROM Contact 
                WHERE Id IN :newContactIds
            ];
            
            for (Contact contact : newlyCreatedContacts) {
                contactKeyToContactMap.put(contact.Contact_Key__c, contact);
            }
            
            // Update tmp__c.contact__c with the new Contact Ids
            for (tmp__c tmpRecord : scope) {
                if (tmpRecord.contact__c == null) {
                    String contactKey = tmpRecord.first__c + '-' + tmpRecord.last__c + '-' + tmpRecord.phone__c + '-' + tmpRecord.locationid__c;
                    if (contactKeyToContactMap.containsKey(contactKey)) {
                        tmpRecord.contact__c = contactKeyToContactMap.get(contactKey).Id;
                    }
                }
            }
        }
        
        // Update tmp__c records with the new practice__c and contact__c values
        if (!tmpToUpdate.isEmpty()) {
            update tmpToUpdate;
        }
    }
    
    // Finish method
    global void finish(Database.BatchableContext BC) {
          // Chain the next batch
       // BatchProcessTmpCases nextBatch = new BatchProcessTmpCases();
       // Database.executeBatch(nextBatch);
    }
}