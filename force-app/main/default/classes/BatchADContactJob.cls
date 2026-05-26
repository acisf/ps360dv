global class BatchADContactJob implements Database.Batchable<SObject>, Database.Stateful {
    
    global DateTime dtStart;
    
    global BatchADContactJob(DateTime dtStart) {
        this.dtStart = dtStart;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Email__c, First_Name__c, Last_Name__c, Phone_Number__c,
            Department__c, Job_Title__c, PracticeDescription__c, Contact__c,
            Location_Id__c, Active__c
            FROM AD_User__c
            WHERE LastModifiedDate >= :dtStart
            AND Email__c != null
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        
        List<Ad_User__c> adUsers = new List<Ad_User__c>();
        for(SObject sObj : scope) adUsers.add((Ad_User__c)sObj);
        
        // -----------------------------
        // Collect emails
        // -----------------------------
        Set<String> emails = new Set<String>();
        for(Ad_User__c ad : adUsers) {
            if(ad.Email__c != null) emails.add(ad.Email__c.trim().toLowerCase().replace('?', ''));
        }
        
        // -----------------------------
        // Existing Contacts
        // -----------------------------
        Map<String, Contact> mapContact = new Map<String, Contact>();
        for(Contact c : [SELECT Id, Email, FirstName, LastName, AccountId, Department, Description,
                         Work_Phone__c, Title, Active_Contact__c
                         FROM Contact
                         WHERE Email IN :emails]) {
                             mapContact.put(c.Email.trim().toLowerCase().replace('?', ''), c);
                         }
        
        // -----------------------------
        // Account / RecordType info
        // -----------------------------
        Id practiceRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Practice Employee').getRecordTypeId();
        Id corporateRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Corporate Employee').getRecordTypeId();
        
        Account corporateAcc = [SELECT Id FROM Account WHERE Name = 'Affordable Care, LLC' LIMIT 1];
        
        Set<String> locationIds = new Set<String>();
        for(Ad_User__c ad : adUsers) {
            if(ad.Location_Id__c != null && ad.Location_Id__c != '0') locationIds.add(ad.Location_Id__c);
        }
        
        Map<String, Id> accountMap = new Map<String, Id>();
        for(Account a : [SELECT Id, Location_Id_5_Digit__c FROM Account WHERE Location_Id_5_Digit__c IN :locationIds]) {
            accountMap.put(a.Location_Id_5_Digit__c, a.Id);
        }
        
        // -----------------------------
        // Prepare DML lists
        // -----------------------------
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Contact> contactsToInsert = new List<Contact>();
        List<Ad_User__c> adUsersToUpdate = new List<Ad_User__c>();
        
        // -----------------------------
        // Email regex for validation
        // -----------------------------
        Pattern emailPattern = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
        
        // -----------------------------
        // Process AD Users
        // -----------------------------
        for(Ad_User__c ad : adUsers) {
            String cleanEmail = ad.Email__c != null 
                ? ad.Email__c.trim().toLowerCase().replace('?', '') 
                : null;
            
            // Skip invalid emails
            if(cleanEmail == null || !emailPattern.matcher(cleanEmail).matches()) {
                System.debug('Skipping AD_User__c due to invalid email: ' + ad.Email__c);
                continue;
            }
            
            // Existing Contact
            Contact c = mapContact.get(cleanEmail);
            Boolean contactChanged = false;
            
            if(c != null) {
                ad.Contact__c = c.Id;
                
                if(c.FirstName != ad.First_Name__c) { c.FirstName = ad.First_Name__c; contactChanged=true; }
                if(c.LastName != ad.Last_Name__c) { c.LastName = ad.Last_Name__c; contactChanged=true; }
                if(c.Work_Phone__c != ad.Phone_Number__c) { c.Work_Phone__c = ad.Phone_Number__c; contactChanged=true; }
                if(c.Department != ad.Department__c) { c.Department = ad.Department__c; contactChanged=true; }
                if(c.Title != ad.Job_Title__c) { c.Title = ad.Job_Title__c; contactChanged=true; }
                if(c.Description != ad.PracticeDescription__c) { c.Description = ad.PracticeDescription__c; contactChanged=true; }
                if(c.Active_Contact__c != ad.Active__c) { c.Active_Contact__c = ad.Active__c; contactChanged=true; }
                
                if(contactChanged) contactsToUpdate.add(c);
                
            } else {
                // New Contact
                Contact newC = new Contact(
                    Email = cleanEmail,
                    FirstName = ad.First_Name__c,
                    LastName = ad.Last_Name__c,
                    Department = ad.Department__c,
                    Title = ad.Job_Title__c,
                    Type__c = ad.Job_Title__c,
                    Description = ad.PracticeDescription__c,
                    Active_Contact__c = ad.Active__c,
                    Work_Phone__c = ad.Phone_Number__c
                );
                
                // Assign Account and RecordType
                if(ad.Location_Id__c != null && ad.Location_Id__c != '0') {
                    Id accId = accountMap.get(ad.Location_Id__c);
                    if(accId == null) {
                        System.debug('Skipping AD_User__c due to missing Account for Location: ' + ad.Email__c + ' Location_Id__c=' + ad.Location_Id__c);
                        continue; // skip insert
                    }
                    newC.AccountId = accId;
                    newC.RecordTypeId = practiceRTId;
                } else {
                    newC.AccountId = corporateAcc.Id;
                    newC.RecordTypeId = corporateRTId;
                }
                
                contactsToInsert.add(newC);
            }
            
            adUsersToUpdate.add(ad);
        }
        
        // -----------------------------
        // Perform DML
        // -----------------------------
        if(!contactsToUpdate.isEmpty()) update contactsToUpdate;
        
        if(!contactsToInsert.isEmpty()) {
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.DuplicateRuleHeader.AllowSave = true;
            Database.SaveResult[] sr = Database.insert(contactsToInsert, dmlOpts);
            
            // Map inserted contacts back to AD_User__c
            Map<String, Id> insertedContacts = new Map<String, Id>();
            for(Integer i=0; i<sr.size(); i++) {
                if(sr[i].isSuccess()) insertedContacts.put(contactsToInsert[i].Email, sr[i].getId());
            }
            
            for(Ad_User__c ad : adUsersToUpdate) {
                if(ad.Contact__c == null && ad.Email__c != null) {
                    Id cid = insertedContacts.get(ad.Email__c.trim().toLowerCase().replace('?', ''));
                    if(cid != null) ad.Contact__c = cid;
                }
            }
        }
        
        if(!adUsersToUpdate.isEmpty()) update adUsersToUpdate;
        
        System.debug('BatchADContactJob executed: processed ' + adUsers.size() + ' AD users');
    }
    
    
    global void finish(Database.BatchableContext bc) { }
}