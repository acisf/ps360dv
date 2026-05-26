global class BatchAceBacklog implements Database.Batchable<SObject> {

    global Date backlogDate;

    // Constructor accepts backlog date
    global BatchAceBacklog(Date inputBacklogDate) {
        this.backlogDate = inputBacklogDate != null ? inputBacklogDate : Date.today();
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, Team__c, Category__c, Subcategory__c,
                   Owner.Name, Owner.Type,
                   RecordType.Name, Status, CreatedDate, 
                   Queue_Name__c
            FROM Case
            WHERE RecordType.Name = 'ACE Service'
            AND IsClosed = FALSE
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Case> caseList = (List<Case>)scope;
        List<ACE_Backlog__c> backlogRecords = new List<ACE_Backlog__c>();

        for (Case c : caseList) {
            ACE_Backlog__c bl = new ACE_Backlog__c();

            bl.Case__c            = c.Id;
            bl.Case_Number__c     = c.CaseNumber;
            bl.Team__c            = c.Team__c;
            bl.Category__c        = c.Category__c;
            bl.Subcategory__c     = c.Subcategory__c;
            bl.Queue_Name__c      = c.Queue_Name__c;
            bl.DateTime_Opened__c = c.CreatedDate;
            bl.Age__c = c.CreatedDate.date().daysBetween(backlogDate);
            bl.Backlog_Date__c    = backlogDate;

            backlogRecords.add(bl);
        }

        if (!backlogRecords.isEmpty()) {
            insert backlogRecords;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: notifications, logging, or chaining next batch
    }
}