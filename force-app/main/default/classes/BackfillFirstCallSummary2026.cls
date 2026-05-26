global class BackfillFirstCallSummary2026 implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Only grab inquiries created in 2026
        return Database.getQueryLocator([
            SELECT Id
            FROM Customer_Inquiry__c
            WHERE CreatedDate = THIS_YEAR
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Customer_Inquiry__c> scope) {
        Set<Id> inquiryIds = new Set<Id>();
        for (Customer_Inquiry__c ci : scope) {
            inquiryIds.add(ci.Id);
        }

        if (inquiryIds.isEmpty()) return;

        // Query all call summaries for these inquiries, ordered by call time
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = [
            SELECT Id, Customer_Inquiry__c, NVMStatsSF__CallTime__c
            FROM NVMStatsSF__NVM_Call_Summary__c
            WHERE Customer_Inquiry__c IN :inquiryIds
            ORDER BY NVMStatsSF__CallTime__c ASC
        ];

        // Map to store earliest call per inquiry
        Map<Id, Id> inquiryToFirstCallMap = new Map<Id, Id>();

        for (NVMStatsSF__NVM_Call_Summary__c call : callSummaries) {
            // Only set the first call if not already set
            if (!inquiryToFirstCallMap.containsKey(call.Customer_Inquiry__c)) {
                inquiryToFirstCallMap.put(call.Customer_Inquiry__c, call.Id);
            }
        }

        // Prepare updates
        List<Customer_Inquiry__c> updates = new List<Customer_Inquiry__c>();
        for (Customer_Inquiry__c ci : scope) {
            if (inquiryToFirstCallMap.containsKey(ci.Id)) {
                ci.First_Call_Summary__c = inquiryToFirstCallMap.get(ci.Id);
                updates.add(ci);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Backfill of First_Call_Summary__c for 2026 inquiries completed.');
    }
}