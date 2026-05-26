global class BatchHRToCRMSecondaryAssignments
    implements Database.Batchable<SObject> {

    public Date importDate;

    public BatchHRToCRMSecondaryAssignments(Date importDate) {
        this.importDate = importDate;
    }

    /* ================================
       START
       ================================ */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   Employee_Number__c,
                   Contact__c
            FROM HR_Data__c
            WHERE Import_Date__c = :importDate
            AND Is_Primary__c = false
            AND Employment_Status__c IN ('Active', 'Pre-Start')
        ]);
    }

    /* ================================
       EXECUTE
       ================================ */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<HR_Data__c> hrRows = (List<HR_Data__c>) scope;

        /* -------------------------------
           STEP 1 — Collect Employee Numbers
           ------------------------------- */
        Set<String> employeeNumbers = new Set<String>();
        for (HR_Data__c hr : hrRows) {
            if (hr.Employee_Number__c != null) {
                employeeNumbers.add(hr.Employee_Number__c);
            }
        }

        if (employeeNumbers.isEmpty()) {
            return;
        }

        /* -------------------------------
           STEP 2 — Lookup Existing Contacts
           ------------------------------- */
        Map<String, Id> contactIdByEmployeeNumber = new Map<String, Id>();

        for (Contact c : [
            SELECT Id, Employee_Number__c
            FROM Contact
            WHERE Employee_Number__c IN :employeeNumbers
        ]) {
            contactIdByEmployeeNumber.put(c.Employee_Number__c, c.Id);
        }

        /* -------------------------------
           STEP 3 — Update HR Rows
           ------------------------------- */
        List<HR_Data__c> hrToUpdate = new List<HR_Data__c>();

        for (HR_Data__c hr : hrRows) {
            Id contactId = contactIdByEmployeeNumber.get(hr.Employee_Number__c);

            if (contactId != null && hr.Contact__c != contactId) {
                hr.Contact__c = contactId;
                hrToUpdate.add(hr);
            }
        }

        if (!hrToUpdate.isEmpty()) {
            update hrToUpdate;
        }
    }

    /* ================================
       FINISH
       ================================ */
    global void finish(Database.BatchableContext bc) {
        // Chain Secondary Assignments batch
        Database.executeBatch(
            new BatchHRLocationAssignment(this.importDate),
            200
        );
    }
}