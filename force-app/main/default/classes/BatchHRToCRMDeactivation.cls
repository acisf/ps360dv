/**
 * Deactivates Contacts only
 * HR_Data__c is authoritative
 *
 * Strategy:
 * - Terminated employees → deactivate Contact
 */
global class BatchHRToCRMDeactivation
    implements Database.Batchable<SObject> {

    public Date importDate;

    public BatchHRToCRMDeactivation(Date importDate) {
        this.importDate = importDate;
    }

    /* =========================================================
       START — HR Snapshot (authoritative)
       ========================================================= */
    global Database.QueryLocator start(Database.BatchableContext bc) {

        String soql =
            'SELECT Id, ' +
            '       Employee_Number__c, ' +
            '       Employment_Status__c ' +
            'FROM HR_Data__c ' +
            'WHERE Employee_Number__c != null';

        if (importDate != null) {
            soql += ' AND Import_Date__c = :importDate';
        }

        return Database.getQueryLocator(soql);
    }

    /* =========================================================
       EXECUTE
       ========================================================= */
    global void execute(Database.BatchableContext bc, List<HR_Data__c> scope) {

        /* -------------------------------a
           STEP 1 — Collect Terminated Employees
           ------------------------------- */
        Set<String> terminatedEmployeeNumbers = new Set<String>();

        for (HR_Data__c hr : scope) {
            if (hr.Employment_Status__c == 'Terminated') {
                terminatedEmployeeNumbers.add(hr.Employee_Number__c);
            }
        }

        if (terminatedEmployeeNumbers.isEmpty()) {
            return;
        }

        /* -------------------------------
           STEP 2 — Resolve Contacts
           ------------------------------- */
        List<Contact> contactsToDeactivate = new List<Contact>();

        for (Contact c : [
            SELECT Id, Active_Contact__c
            FROM Contact
            WHERE Employee_Number__c IN :terminatedEmployeeNumbers
        ]) {
            if (c.Active_Contact__c) {
                c.Active_Contact__c = false;
                contactsToDeactivate.add(c);
            }
        }

        /* -------------------------------
           STEP 3 — Update Contacts
           ------------------------------- */
        if (!contactsToDeactivate.isEmpty()) {
            Database.update(contactsToDeactivate, false);
        }
        
          /* -------------------------------
           STEP 4 — Update Location Assignments
           ------------------------------- */
         List<Location_Assignment__c> assignments = new List<Location_Assignment__c>();
         assignments = [SELECT Id, Active__c 
                       FROM Location_Assignment__c
                       WHERE Contact__c IN:contactsToDeactivate ];
        
        for(Location_Assignment__c la: assignments) {
            la.Active__c = false;
        }
        
        if(!assignments.isEmpty())  {
            Database.update(assignments, false);
        }
            

        
        
    }

    /* =========================================================
       FINISH
       ========================================================= */
    global void finish(Database.BatchableContext bc) {
        // intentionally empty
    }
}