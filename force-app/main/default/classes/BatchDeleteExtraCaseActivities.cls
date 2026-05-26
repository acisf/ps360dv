public class BatchDeleteExtraCaseActivities implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Case__c, Activity_Date_Time__c, Customer_Communication__c, CreatedDate
            FROM Case_Activity__c
            WHERE Customer_Communication__c = TRUE
            AND Case__r.CreatedDate < :System.today().addDays(-30)
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Case_Activity__c> activities = (List<Case_Activity__c>)scope;

        Set<Id> caseIds = new Set<Id>();
        for (Case_Activity__c ca : activities) {
            caseIds.add(ca.Case__c);
        }

        Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id, First_Response_Time__c FROM Case WHERE Id IN :caseIds]
        );

        List<Case_Activity__c> toDelete = new List<Case_Activity__c>();
        for (Case_Activity__c ca : activities) {
            if (caseMap.containsKey(ca.Case__c)) {
                DateTime firstResponse = caseMap.get(ca.Case__c).First_Response_Time__c;
                if (ca.Activity_Date_Time__c != firstResponse) {
                    toDelete.add(ca);
                }
            }
        }
        
        System.debug(toDelete.size());
        
        for(Case_Activity__c ca: toDelete) {
            System.debug(ca.Case__c);
        }

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
        
      
    }

    public void finish(Database.BatchableContext bc) {}
}