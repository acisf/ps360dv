global class BatchHRToCRMContactSync
    implements Database.Batchable<SObject> {

    public Date importDate;

    public BatchHRToCRMContactSync(Date importDate) {
        this.importDate = importDate;
    }

    /* ================================
       START
       ================================ */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   Employee_Number__c,
                   Practice_ID__c,
                   First_Name__c,
                   Last_Name__c,
                   Preferred_First_Name__c,
                   Email_Address__c,
                   Job_Title__c,
                   Department_Name__c,
                   Department_Reference_Code__c,
                   Employment_Status__c,
                   Is_Primary__c,
                   Contact__c
            FROM HR_Data__c
            WHERE Import_Date__c = :importDate
            AND Is_Primary__c = true
            AND Employment_Status__c IN ('Active', 'Pre-Start')
        ]);
    }

    /* ================================
       EXECUTE
       ================================ */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<HR_Data__c> hrRows = (List<HR_Data__c>) scope;

        /* -------------------------------
           STEP 1 — Collect Keys
           ------------------------------- */
        Set<String> employeeNumbers = new Set<String>();
        Set<String> practiceIds = new Set<String>();

        for (HR_Data__c hr : hrRows) {
            if (hr.Employee_Number__c != null) {
                employeeNumbers.add(hr.Employee_Number__c);
            }

            if (isNumeric(hr.Practice_ID__c)) {
                practiceIds.add(normalizePracticeId(hr.Practice_ID__c));
            }
        }

        /* -------------------------------
           STEP 2 — Existing Contacts
           ------------------------------- */
        Map<String, Contact> contactsByEmployeeNumber = new Map<String, Contact>();
        for (Contact c : [
            SELECT Id,
                   FirstName,
                   LastName,
                   Email,
                   Title,
                   Department,
                   Department_Ref__c,
                   Employee_Number__c,
                   Active_Contact__c,
                   RecordTypeId,
                   AccountId
            FROM Contact
            WHERE Employee_Number__c IN :employeeNumbers
        ]) {
            contactsByEmployeeNumber.put(c.Employee_Number__c, c);
        }

        /* -------------------------------
           STEP 3 — Account Resolution
           ------------------------------- */
        Map<String, Account> practiceAccountMap = new Map<String, Account>();
        if (!practiceIds.isEmpty()) {
            for (Account a : [
                SELECT Id, Location_Id__c
                FROM Account
                WHERE Location_Id__c IN :practiceIds
            ]) {
                practiceAccountMap.put(a.Location_Id__c, a);
            }
        }

        Account dsoAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Affordable Care, LLC'
            LIMIT 1
        ];

        /* -------------------------------
           STEP 4 — Record Types
           ------------------------------- */
        Id practiceRt =
            Schema.SObjectType.Contact.getRecordTypeInfosByName()
                .get('Practice Employee')
                .getRecordTypeId();

        Id corporateRt =
            Schema.SObjectType.Contact.getRecordTypeInfosByName()
                .get('Corporate Employee')
                .getRecordTypeId();

        /* -------------------------------
           STEP 5 — Create / Update Contacts
           ------------------------------- */
        List<Contact> contactsToInsert = new List<Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Batch_Error_Log__c> errorLogs = new List<Batch_Error_Log__c>();

        Map<String, HR_Data__c> hrByEmployeeNumber = new Map<String, HR_Data__c>();
        for (HR_Data__c hr : hrRows) {
            hrByEmployeeNumber.put(hr.Employee_Number__c, hr);
        }

        for (HR_Data__c hr : hrRows) {

            Boolean isCorporate = !isNumeric(hr.Practice_ID__c);
            String normalizedPid = normalizePracticeId(hr.Practice_ID__c);

            Account account =
                isCorporate
                    ? dsoAccount
                    : practiceAccountMap.get(normalizedPid);

            if (account == null) {
                errorLogs.add(new Batch_Error_Log__c(
                    Job_Name__c = 'BatchHRToCRMContactSync',
                    External_Id__c = hr.Employee_Number__c,
                    Error_Message__c = 'No Account found for Practice_ID__c: ' + hr.Practice_ID__c
                ));
                continue;
            }

            Id recordTypeId = isCorporate ? corporateRt : practiceRt;

            Contact c = contactsByEmployeeNumber.get(hr.Employee_Number__c);

            if (c == null) {
                // CREATE
                c = new Contact(
                    FirstName = String.isBlank(hr.Preferred_First_Name__c)
                        ? hr.First_Name__c
                        : hr.Preferred_First_Name__c,
                    LastName = hr.Last_Name__c,
                    Email = hr.Email_Address__c,
                    Title = hr.Job_Title__c,
                    Employee_Number__c = hr.Employee_Number__c,
                    Active_Contact__c = true,
                    Department = hr.Department_Name__c,
                    Department_Ref__c = hr.Department_Reference_Code__c,
                    RecordTypeId = recordTypeId,
                    AccountId = account.Id
                );
                contactsToInsert.add(c);
            } else {
                // UPDATE
                c.FirstName =
                    String.isBlank(hr.Preferred_First_Name__c)
                        ? hr.First_Name__c
                        : hr.Preferred_First_Name__c;
                c.LastName = hr.Last_Name__c;
                c.Email = hr.Email_Address__c;
                c.Title = hr.Job_Title__c; 
                c.Department = hr.Department_Name__c;
                c.Department_Ref__c = hr.Department_Reference_Code__c;
                c.Active_Contact__c = true;
                c.RecordTypeId = recordTypeId;
                c.AccountId = account.Id;

                contactsToUpdate.add(c);
            }
        }

        /* -------------------------------
           STEP 6 — DML + HR Linking
           ------------------------------- */
        if (!contactsToInsert.isEmpty()) {
            Database.SaveResult[] results =
                Database.insert(contactsToInsert, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    String empNum = contactsToInsert[i].Employee_Number__c;
                    hrByEmployeeNumber.get(empNum).Contact__c = results[i].getId();
                } else {
                    for (Database.Error err : results[i].getErrors()) {
                        errorLogs.add(new Batch_Error_Log__c(
                            Job_Name__c = 'BatchHRToCRMContactSync',
                            External_Id__c = contactsToInsert[i].Employee_Number__c,
                            Error_Message__c = err.getMessage()
                        ));
                    }
                }
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            Database.SaveResult[] results =
                Database.update(contactsToUpdate, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    Contact c = contactsToUpdate[i];
                    hrByEmployeeNumber.get(c.Employee_Number__c).Contact__c = c.Id;
                } else {
                    for (Database.Error err : results[i].getErrors()) {
                        errorLogs.add(new Batch_Error_Log__c(
                            Job_Name__c = 'BatchHRToCRMContactSync',
                            External_Id__c = contactsToUpdate[i].Employee_Number__c,
                            Error_Message__c = err.getMessage()
                        ));
                    }
                }
            }
        }
        

        /* -------------------------------
           STEP 8 — Update HR + Log Errors
           ------------------------------- */
        update hrRows;

        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }
      
    /* ================================
       HELPERS
       ================================ */
    private static Boolean isNumeric(String value) {
        return !String.isBlank(value) && Pattern.matches('\\d+', value);
    }

    private static String normalizePracticeId(String value) {
        if (!isNumeric(value)) return null;
        return String.valueOf(Integer.valueOf(value)).leftPad(5, '0');
    }

  global void finish(Database.BatchableContext bc) { 
        // Chain Secondary Assignments batch
        Database.executeBatch(
            new BatchHRToCRMSecondaryAssignments(this.importDate),
            200
        );
  }

}