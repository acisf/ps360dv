global class ScheduleCallSummaryUpdateBackfillQ12025 implements Schedulable {

    global void execute(SchedulableContext SC) {

        List<NVMStatsSF__NVM_Call_Summary__c> lstCS;

        // Define date range: Jan 1 – March 31, 2025
        Date startDate = Date.newInstance(2025, 1, 1);
        Date endDate   = Date.newInstance(2025, 3, 31);

        lstCS = [
            SELECT Id,
                   Call_Result_Subcategory__c,
                   NVMStatsSF__TaskID__c,
                   Reason_for_Not_Scheduling__c,
                   Insurance_Plan__c
            FROM NVMStatsSF__NVM_Call_Summary__c
            WHERE
                CreatedDate >= :startDate
                AND CreatedDate <= :endDate
                AND (
                    NVMStatsSF__CallDisposition__c = 'Fees/Services'
                    OR NVMStatsSF__CallDisposition__c = 'Scheduled'
                )
                AND NVMStatsSF__TaskExists__c = TRUE
                AND (
                    Call_Result_Subcategory__c = ''
                    OR Reason_for_Not_Scheduling__c = ''
                    OR Insurance_Plan__c = ''
                )
        ];

        Database.executeBatch(new CallSummaryUpdate(lstCS), 100);
    }
}