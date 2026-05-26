public class ContactPatientMatchBatch implements Database.Batchable<SObject>, Database.Stateful { 
    
    private DateTime createdStart;
    private DateTime createdEnd;
    private Id patientRecordTypeId;
    
    public ContactPatientMatchBatch(Date dtCreated) {
        createdStart = DateTime.newInstance(dtCreated, Time.newInstance(0,0,0,0));
        createdEnd = DateTime.newInstance(dtCreated + 1, Time.newInstance(0,0,0,0));
        patientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
    }
    
    // Start method
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, user_Id__c, first_name__c, last_name__c, email__c, practice_id__c, phone_appointment__c, mobile_phone__c, home_phone__c, new_patient__c, patient_id__c ' +
                       'FROM Zeta_User__c ' +
                       'WHERE CreatedDate >= :createdStart AND CreatedDate <= :createdEnd';
        return Database.getQueryLocator(query);
    }
    
    // Execute method
    public void execute(Database.BatchableContext BC, List<Zeta_User__c> scope) {
        Map<String, Zeta_User__c> contactKeyToZetaUserMap = new Map<String, Zeta_User__c>();

        // Step 1: Sanitize and generate contact keys
        for (Zeta_User__c zUser : scope) {
            sanitizeZetaUser(zUser);
            String contactKey = generateContactKey(zUser);
            contactKeyToZetaUserMap.put(contactKey, zUser);
        }

        // Step 2: Query existing Contacts based on generated keys
        Set<String> contactKeys = contactKeyToZetaUserMap.keySet();
        List<Contact> existingContacts = [
            SELECT Id, Contact_Key__c, Last_Appt_Date__c, Last_Appt_Status__c, Pat_ID_DB__c 
            FROM Contact 
            WHERE Contact_Key__c IN :contactKeys 
              AND RecordTypeId = :patientRecordTypeId
        ];

        // Step 3: Update Contacts with matched Zeta_User__c records
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact contact : existingContacts) {
            String contactKey = contact.Contact_Key__c;
            if (contactKeyToZetaUserMap.containsKey(contactKey)) {
                Zeta_User__c matchedZetaUser = contactKeyToZetaUserMap.get(contactKey);
                contact.Pat_ID_DB__c = matchedZetaUser.user_Id__c;
                contactsToUpdate.add(contact);
            }
        }

        // Step 4: Process Zeta Events (filtered) and get only contacts with relevant events
        List<Contact> contactsWithRelevantEvents = processZetaEvents(contactsToUpdate);

        // Step 5: Query and close open 'Outbound Campaign' cases only for relevant contacts
        if (!contactsWithRelevantEvents.isEmpty()) {
            List<Case> openCases = getOpenOutboundCampaignCases(contactsWithRelevantEvents);
        
        // Delete Pedning Dial Entries before closing the cases
        
            // Create a list of case IDs to use for matching the Pending Dial Entry records 
            Set<Id> caseIds = new set<Id>(); 
            for (Case c: openCases) {
                caseIds.add(c.Id); 
            }
            // get pending dial entry records that match the case ID 
            if(!caseIds.isEmpty()){
                List<NVMConnect__PendingDialEntry__c> PendingDialEntries = [
                     SELECT Id, Name, NVMConnect__Indexed_Focus_Object_Id__c 
                     FROM NVMConnect__PendingDialEntry__c
                     WHERE NVMConnect__Indexed_Focus_Object_Id__c IN:caseIds
                ]; 
                // Delete Pending Dial Entry Records 
                 if(!PendingDialEntries.isEmpty()){
                delete PendingDialEntries; 
                 }
            }
            
            for (Case c : openCases) {
                c.Status = 'Closed';
            }
            if (!openCases.isEmpty()) {
                update openCases;
            }
        }

        // Step 6: Update all matched Contacts
        if (!contactsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(contactsToUpdate, false);
            for (Database.SaveResult result : updateResults) {
                if (result.isSuccess()) {
                    System.debug('Successfully updated Contact with ID: ' + result.getId());
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Failed to update Contact with ID: ' + result.getId() + '. Error: ' + error.getMessage());
                    }
                }
            }
        }
    }
    
    // Finish method
    public void finish(Database.BatchableContext BC) {
        // No specific finish logic
    }
    
    // Query open Outbound Campaign cases for given contacts
    public List<Case> getOpenOutboundCampaignCases(List<Contact> contacts) {
        if (contacts.isEmpty()) return new List<Case>();
        
        Set<Id> contactIds = new Set<Id>();
        for (Contact contact : contacts) {
            contactIds.add(contact.Id);
        }

        return [
            SELECT Id, Status, ContactId 
            FROM Case 
            WHERE RecordType.Name = 'Outbound Campaign' 
              AND isClosed = FALSE 
              AND ContactId IN :contactIds
        ];
    }

    // Sanitize Zeta_User__c data
    private void sanitizeZetaUser(Zeta_User__c zUser) {
        if (zUser.phone_appointment__c != null) {
            String sanitizedPhone = zUser.phone_appointment__c.replaceAll('[^0-9]', '');
            if (sanitizedPhone.length() > 10) {
                sanitizedPhone = sanitizedPhone.substring(sanitizedPhone.length() - 10);
            }
            zUser.phone_appointment__c = sanitizedPhone;
        }
        if (zUser.first_name__c != null) zUser.first_name__c = zUser.first_name__c.trim().toLowerCase();
        if (zUser.last_name__c != null) zUser.last_name__c = zUser.last_name__c.trim().toLowerCase();
        if (zUser.practice_id__c != null) {
            String practiceId = zUser.practice_id__c.trim();
            if (practiceId.length() == 4 && Pattern.matches('\\d{4}', practiceId)) {
                practiceId = '0' + practiceId; 
            }
            if (practiceId.length() == 5 && Pattern.matches('\\d{5}', practiceId)) {
                zUser.practice_id__c = practiceId;
            } else {
                System.debug('Invalid practice_id: ' + practiceId);
            }
        }
    }

    // Generate a unique contact key
    private String generateContactKey(Zeta_User__c zUser) {
        String phone = zUser.phone_appointment__c != null ? zUser.phone_appointment__c : zUser.home_phone__c;
        return zUser.first_name__c + '-' + zUser.last_name__c + '-' + phone + '-' + zUser.practice_id__c;
    }

    // Process Zeta events and return only contacts with relevant events
    private List<Contact> processZetaEvents(List<Contact> contactsToUpdate) {
        Set<String> userIds = new Set<String>();
        for (Contact contact : contactsToUpdate) {
            if (contact.Pat_ID_DB__c != null) userIds.add(contact.Pat_ID_DB__c);
        }

        // Get only 'new_appt' or 'rescheduled_appt' events
        List<Zeta_Event__c> zetaEvents = getZetaEvents(userIds);

        // Map userId -> latest event
        Map<String, Zeta_Event__c> userIdToLatestEvent = new Map<String, Zeta_Event__c>();
        for (Zeta_Event__c zEvent : zetaEvents) {
            if (!userIdToLatestEvent.containsKey(zEvent.user_id__c) || 
                zEvent.timestamp__c > userIdToLatestEvent.get(zEvent.user_id__c).timestamp__c) {
                userIdToLatestEvent.put(zEvent.user_id__c, zEvent);
            }
        }

        // Update contacts and collect only those with relevant events
        List<Contact> contactsWithRelevantEvents = new List<Contact>();
        for (Contact contact : contactsToUpdate) {
            if (userIdToLatestEvent.containsKey(contact.Pat_ID_DB__c)) {
                Zeta_Event__c latestEvent = userIdToLatestEvent.get(contact.Pat_ID_DB__c);
                contact.Last_Appt_Date__c = Date.parse(latestEvent.apptdate__c);
                contact.Last_Appt_Status__c = latestEvent.event_type__c.replace('_',' ');
                contactsWithRelevantEvents.add(contact);
            }
        }
        return contactsWithRelevantEvents;
    }

    // Query Zeta events for relevant userIds and event types
    public List<Zeta_Event__c> getZetaEvents(Set<String> userIds) {
        if (userIds.isEmpty()) return new List<Zeta_Event__c>();

        return [
            SELECT Id, user_id__c, event_type__c, practiceid__c, apptid__c, apptdate__c, timestamp__c
            FROM Zeta_Event__c 
            WHERE CreatedDate >= :createdStart
              AND CreatedDate <= :createdEnd
              AND user_id__c IN :userIds
              AND event_type__c IN ('new_appt', 'rescheduled_appt')
            ORDER BY timestamp__c
        ];
    }
}