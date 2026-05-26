/*****
 * 
 * Run daily at 11pm
 * 
****/

global class ScheduleBatchCallCenterSummary  implements Schedulable  {
    global void execute(SchedulableContext SC) { 
        Date theDate = Date.today() - 1;
        BatchCallCenterSummary batch = new BatchCallCenterSummary(theDate);
        Database.executeBatch(batch, 1); 
    }
}