// System.schedule('Call Summary 1', '0 0 * * * ?', new ScheduleCallSummaryUpdate());
// System.schedule('Call Summary 3', '0 30 * * * ?', new ScheduleCallSummaryUpdate());

global class ScheduleCallSummaryUpdate  implements Schedulable  {
  global void execute(SchedulableContext SC) { 
      List<NVMStatsSF__NVM_Call_Summary__c> lstCS; 
      DateTime dtOneHour = DateTime.now().addMinutes(-60);
      DateTime dt15Min = DateTime.now().addMinutes(-15);
      
      lstCS = [Select Id,Call_Result_Subcategory__c,NVMStatsSF__TaskID__c,Reason_for_Not_Scheduling__c, Insurance_Plan__c from NVMStatsSF__NVM_Call_Summary__c 
               where 
               CreatedDate = TODAY AND
               (NVMStatsSF__CallDisposition__c =: 'Fees/Services'OR
                NVMStatsSF__CallDisposition__c =: 'Scheduled') AND
               NVMStatsSF__TaskExists__c = TRUE AND
               (Call_Result_Subcategory__c = '' OR
               Reason_for_Not_Scheduling__c = '' OR
               Insurance_Plan__c = '') ];
      
      Database.executeBatch(new CallSummaryUpdate(lstCS),100);    
  }
}