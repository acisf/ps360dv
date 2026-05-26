global class BatchHRLocationAssignment implements Database.Batchable<SObject>, Database.Stateful {

    public Date importDate;
    
    public BatchHRLocationAssignment(Date importDate) {
        this.importDate = importDate;
    }

    // ------------------------------------------------------------
    // START
    // ------------------------------------------------------------
    global Database.QueryLocator start(Database.BatchableContext bc) {

        String soql =
            'SELECT Id, Contact__c, Practice_ID__c, ' +
            '       Primary_Job_Assignment__c, ' +
            '       Department_Name__c, ' +
            '       Department_Reference_Code__c, ' +
            '       Employment_Status__c ' +
            'FROM HR_Data__c ' +
            'WHERE Contact__c != null ' +
            'AND Practice_ID__c != null ' +
            'AND Department_Reference_Code__c != null';

        if (importDate != null) {
            soql += ' AND Import_Date__c = :importDate';
        }

        return Database.getQueryLocator(soql);
    }

    // ------------------------------------------------------------
    // EXECUTE
    // ------------------------------------------------------------
    global void execute(Database.BatchableContext bc, List<HR_Data__c> scope) {

        // 1️⃣ Collect Practice IDs
        Set<String> practiceIds = new Set<String>();
        for (HR_Data__c hr : scope) {
            if (isNumeric(hr.Practice_ID__c)) {
                practiceIds.add(normalizePracticeId(hr.Practice_ID__c));
            }
        }

        // 2️⃣ Resolve Accounts
        Map<String, Account> accountByPractice = new Map<String, Account>();
        for (Account a : [
            SELECT Id, Location_ID__c
            FROM Account
            WHERE Location_ID__c IN :practiceIds
        ]) {
            accountByPractice.put(a.Location_ID__c, a);
        }
        
        Account dsoAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Affordable Care, LLC'
            LIMIT 1
        ];

        // 3️⃣ Build Location Assignments
        List<Location_Assignment__c> upserts = new List<Location_Assignment__c>();
        Set<String> keys = new Set<String>();

        for (HR_Data__c hr : scope) {

            Boolean isCorporate = !isNumeric(hr.Practice_ID__c);
            String normalizedPid = normalizePracticeId(hr.Practice_ID__c);

            Account acct =
                isCorporate
                    ? dsoAccount
                    : accountByPractice.get(normalizedPid);

            if (acct == null) continue;

            String externalKey =
                hr.Contact__c + '-' +
                acct.Id + '-' +
                hr.Department_Reference_Code__c;

            Location_Assignment__c la = new Location_Assignment__c();
            la.External_Key__c           = externalKey;
            la.Contact__c                = hr.Contact__c;
            la.Account__c                = acct.Id;
            la.Primary_Job_Assignment__c = hr.Primary_Job_Assignment__c;
            la.Department_Name__c        = hr.Department_Name__c;
            la.Department_Ref_Code__c    = hr.Department_Reference_Code__c;
            la.Active__c                 = (hr.Employment_Status__c == 'Active' || hr.Employment_Status__c == 'Pre-Start');

            if (keys.add(externalKey)) {
                upserts.add(la);
            }
        }

        // 4️⃣ Upsert by External ID
        if (!upserts.isEmpty()) {
            upsert upserts External_Key__c;
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

    // ------------------------------------------------------------
    // FINISH
    // ------------------------------------------------------------
    global void finish(Database.BatchableContext bc) {
        // Chain deactivate batch
        Database.executeBatch(
            new BatchHRToCRMDeactivation(this.importDate),
            200
        );
    }
}