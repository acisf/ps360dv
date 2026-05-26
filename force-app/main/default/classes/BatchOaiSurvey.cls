global class BatchOaiSurvey implements Database.Batchable<SObject> {

    private Date startDate;
    private Date endDate;

    // Default: today only
    global BatchOaiSurvey() {
        Date today = Date.today();
        this.startDate = today;
        this.endDate   = today;
    }

    // Explicit date range (inclusive)
    global BatchOaiSurvey(Date startDate, Date endDate) {
        Date s = startDate != null ? startDate : Date.today();
        Date e = endDate   != null ? endDate   : s;
        this.startDate = s <= e ? s : e;
        this.endDate   = s <= e ? e : s;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {

        DateTime startDt =
            DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        DateTime endDt =
            DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));

        return Database.getQueryLocator([
            SELECT Id, Call_GUID__c
            FROM OAI_Survey__c
            WHERE CreatedDate >= :startDt
              AND CreatedDate <  :endDt
              AND Vonage_Call_Summary__c = null
              AND Call_GUID__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<OAI_Survey__c> scope) {

        Set<String> callGuids = new Set<String>();
        for (OAI_Survey__c s : scope) {
            callGuids.add(s.Call_GUID__c);
        }

        if (callGuids.isEmpty()) {
            return;
        }

        Map<String, Id> guidToSummaryId = new Map<String, Id>();
        for (NVMStatsSF__NVM_Call_Summary__c cs : [
            SELECT Id, NVMStatsSF__CallGuid__c
            FROM NVMStatsSF__NVM_Call_Summary__c
            WHERE NVMStatsSF__CallGuid__c IN :callGuids
        ]) {
            guidToSummaryId.put(cs.NVMStatsSF__CallGuid__c, cs.Id);
        }

        List<OAI_Survey__c> updates = new List<OAI_Survey__c>();
        for (OAI_Survey__c s : scope) {
            if (guidToSummaryId.containsKey(s.Call_GUID__c)) {
                s.Vonage_Call_Summary__c =
                    guidToSummaryId.get(s.Call_GUID__c);
                updates.add(s);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(
            'BatchOaiSurvey completed for range ' +
            startDate + ' → ' + endDate
        );
    }
}