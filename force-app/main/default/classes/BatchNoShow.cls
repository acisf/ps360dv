public class BatchNoShow implements Database.Batchable<SObject>, Database.Stateful {
    
    private DateTime createdStart;
    private DateTime createdEnd;
    private Id patientRecordTypeId;
    private Id outboundCampaignCaseRTId;
    private Id groupId;
    
    public BatchNoShow(Date dtCreated) {
        createdStart = DateTime.newInstance(dtCreated, Time.newInstance(0,0,0,0));
        createdEnd = DateTime.newInstance(dtCreated.addDays(1), Time.newInstance(0,0,0,0));
        patientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
        outboundCampaignCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Outbound Campaign').getRecordTypeId();
        groupId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Outbound_Campaign' LIMIT 1].Id;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, user_id__c, first_name__c, last_name__c, email__c,
            mobile_phone__c, home_phone__c, phone_appointment__c,
            practice_id__c, dob__c, gender__c
            FROM Zeta_User__c
            WHERE CreatedDate >= :createdStart AND CreatedDate < :createdEnd
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Zeta_User__c> scope) {
        Map<String, Zeta_User__c> contactKeyToZetaUserMap = new Map<String, Zeta_User__c>();
        Map<String, String> userIdToPracticeId = new Map<String, String>();
        
        // Step 1: sanitize + keys
        for (Zeta_User__c zUser : scope) {
            sanitizeZetaUser(zUser);
            String contactKey = generateContactKey(zUser);
            contactKeyToZetaUserMap.put(contactKey, zUser);
            if (zUser.user_id__c != null && zUser.practice_id__c != null) {
                userIdToPracticeId.put(zUser.user_id__c, zUser.practice_id__c);
            }
        }
        
        // Step 2: bulk query accounts once
        Set<String> practiceIds = new Set<String>();
        for (Zeta_User__c zUser : scope) {
            if (zUser.practice_id__c != null) {
                practiceIds.add(zUser.practice_id__c);
            }
        }
        
        Map<String, Id> practiceIdToAccountId = new Map<String, Id>();
        if (!practiceIds.isEmpty()) {
            for (Account acct : [
                SELECT Id, Location_Id__c
                FROM Account
                WHERE Location_Id__c IN :practiceIds
            ]) {
                practiceIdToAccountId.put(acct.Location_Id__c, acct.Id);
            }
        }
        
        // Step 3: query existing contacts
        Set<String> contactKeys = contactKeyToZetaUserMap.keySet();
        List<Contact> existingContacts = [
            SELECT Id, Contact_Key__c, AccountId, Email, FirstName, LastName,
            MobilePhone, OtherPhone, Pat_ID_DB__c, Location_Id__c
            FROM Contact
            WHERE Contact_Key__c IN :contactKeys
            AND RecordTypeId = :patientRecordTypeId
        ];
        
        Map<String, Contact> contactKeyToContact = new Map<String, Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact c : existingContacts) {
            contactKeyToContact.put(c.Contact_Key__c, c);
            
            // backfill missing Pat_ID_DB__c
            Zeta_User__c zUser = contactKeyToZetaUserMap.get(c.Contact_Key__c);
            if (c.Pat_ID_DB__c == null && zUser != null && !String.isBlank(zUser.user_id__c)) {
                c.Pat_ID_DB__c = zUser.user_id__c;
                contactsToUpdate.add(c);
            }
        }
        
        List<Contact> contactsToInsert = new List<Contact>();
        List<Contact> contactsInScope = new List<Contact>();
        
        // Step 4: create missing contacts
        for (String key : contactKeyToZetaUserMap.keySet()) {
            Zeta_User__c zUser = contactKeyToZetaUserMap.get(key);
            if (contactKeyToContact.containsKey(key)) {
                contactsInScope.add(contactKeyToContact.get(key));
            } else {
                Contact newContact = mapZetaUserToContact(zUser, key, practiceIdToAccountId);
                contactsToInsert.add(newContact);
            }
        }
        
        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
            contactsInScope.addAll(contactsToInsert);
        }
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
        // Step 5: process events → create deduped Cases
        processNoShowEventsAndCreateCases(contactsInScope, userIdToPracticeId);
    }
    
    public void finish(Database.BatchableContext bc) {
        // no post-processing
    }
    
    //
    // ---------- Helpers ----------
    //
    
    @TestVisible
    private void sanitizeZetaUser(Zeta_User__c zUser) {
        if (zUser.phone_appointment__c != null) {
            String sanitizedPhone = zUser.phone_appointment__c.replaceAll('[^0-9]', '');
            if (sanitizedPhone.length() > 10) {
                sanitizedPhone = sanitizedPhone.substring(sanitizedPhone.length() - 10);
            }
            zUser.phone_appointment__c = sanitizedPhone;
        }
        if (zUser.first_name__c != null) {
            zUser.first_name__c = zUser.first_name__c.trim().toLowerCase();
        }
        if (zUser.last_name__c != null) {
            zUser.last_name__c = zUser.last_name__c.trim().toLowerCase();
        }
        if (zUser.practice_id__c != null) {
            String practiceId = zUser.practice_id__c.trim();
            if (practiceId.length() == 4 && Pattern.matches('\\d{4}', practiceId)) {
                practiceId = '0' + practiceId;
            }
            zUser.practice_id__c = practiceId;
        }
    }
    
    @TestVisible
    private String generateContactKey(Zeta_User__c zUser) {
        String first = (zUser.first_name__c != null) ? zUser.first_name__c.trim().toLowerCase() : '';
        String last = (zUser.last_name__c != null) ? zUser.last_name__c.trim().toLowerCase() : '';
        
        String phone = null;
        if (!String.isBlank(zUser.phone_appointment__c)) {
            phone = zUser.phone_appointment__c;
        } else if (!String.isBlank(zUser.mobile_phone__c)) {
            phone = zUser.mobile_phone__c;
        } else if (!String.isBlank(zUser.home_phone__c)) {
            phone = zUser.home_phone__c;
        }
        
        if (!String.isBlank(phone)) {   
            String digits = phone.replaceAll('[^0-9]', '');
            String lastTen = (digits.length() > 10) ? digits.substring(digits.length() - 10) : digits;
            phone = lastTen.leftPad(10, '0');
        }
        
        String location = (zUser.practice_id__c != null) ? zUser.practice_id__c.trim() : '';
        
        return first + '-' + last + '-' + phone + '-' + location;
    }
    
    @TestVisible
    private Contact mapZetaUserToContact(Zeta_User__c zUser, String contactKey, Map<String, Id> practiceIdToAccountId) {
        Contact c = new Contact();
        c.RecordTypeId = patientRecordTypeId;
        c.FirstName = zUser.first_name__c != null ? zUser.first_name__c.capitalize() : null;
        c.LastName = zUser.last_name__c != null ? zUser.last_name__c.capitalize() : 'Unknown';
        
        if(Validator.isValidEmail(zUser.email__c)) {
            c.Email = zUser.email__c;
        }        
        
        if (!String.isBlank(zUser.phone_appointment__c)) {
            c.MobilePhone = zUser.phone_appointment__c;
        } else if (!String.isBlank(zUser.mobile_phone__c)) {
            c.MobilePhone = zUser.mobile_phone__c;
        } else if (!String.isBlank(zUser.home_phone__c)) {
            c.MobilePhone = zUser.home_phone__c;
        }
        c.OtherPhone = zUser.home_phone__c;
        c.Pat_ID_DB__c = zUser.user_id__c;
        
        if (zUser.practice_id__c != null && practiceIdToAccountId.containsKey(zUser.practice_id__c)) {
            c.AccountId = practiceIdToAccountId.get(zUser.practice_id__c);
        }
        
        return c;
    }
    
    @TestVisible
    private void processNoShowEventsAndCreateCases(List<Contact> contacts, Map<String, String> userIdToPracticeId) {
        if (contacts.isEmpty()) return;
        
        Set<String> userIds = new Set<String>();
        Map<String, Contact> userIdToContact = new Map<String, Contact>();
        for (Contact c : contacts) {
            if (c.Pat_ID_DB__c != null) {
                userIds.add(c.Pat_ID_DB__c);
                userIdToContact.put(c.Pat_ID_DB__c, c);
            }
        }
        
        List<Zeta_Event__c> zEvents = [
            SELECT Id, user_id__c, event_type__c, apptdate__c,appttime__c,apptdatetime__c,timestamp__c
            FROM Zeta_Event__c
            WHERE user_id__c IN :userIds
        ];
        
        Set<Id> dedupedContactIds = new Set<Id>();
        List<Case> casesToInsert = new List<Case>();
        
        for (Zeta_Event__c ze : zEvents) {
            if (ze.event_type__c != null && ze.event_type__c.equalsIgnoreCase('no_show')) {
                Contact relatedContact = userIdToContact.get(ze.user_id__c);
                if (relatedContact != null && !dedupedContactIds.contains(relatedContact.Id)) {
                    // pick location from Contact first, fallback to Zeta_User.practice_id__c
                    String locationId = relatedContact.Location_Id__c;
                    if (String.isBlank(locationId) && userIdToPracticeId.containsKey(ze.user_id__c)) {
                        locationId = userIdToPracticeId.get(ze.user_id__c);
                    }
                    
                    Case newCase = new Case();
                    newCase.ownerId = groupId;
                    newCase.RecordTypeId = outboundCampaignCaseRTId;
                    newCase.ContactId = relatedContact.Id;
                    newCase.AccountId = relatedContact.AccountId;
                    newCase.Origin = 'System';
                    newCase.Status = 'New';
                    newCase.Subject = 'Appointment No Show - ' + (locationId != null ? locationId : '');
                    newCase.Offer__c = 'Appt No Show';
                    
                    String phone = relatedContact.MobilePhone != null ? relatedContact.MobilePhone : relatedContact.OtherPhone;
                    newCase.Description =
                        'First: ' + (relatedContact.FirstName != null ? relatedContact.FirstName : '') + '\n' +
                        'Last: ' + (relatedContact.LastName != null ? relatedContact.LastName : '') + '\n' +
                        'Location ID: ' + (locationId != null ? locationId : '') + '\n' +
                        'Appt Date: ' + ze.apptdate__c + '\n' +
                        'Appt Time: ' + ze.appttime__c + '\n' +
                        'Phone: ' + (phone != null ? phone : '') + '\n' +
                        'Offer: Appt No Show';
                    
                    casesToInsert.add(newCase);
                    dedupedContactIds.add(relatedContact.Id);
                }
            }
        }
        
        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
        }
    }
}