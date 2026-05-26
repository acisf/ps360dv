//System.schedule('EmailOptOut','0 5 0 1/1 * ? *', new ScheduleBatchEmailOptOut());
global class ScheduleBatchEmailOptOut implements Schedulable {
    
    global void execute(SchedulableContext SC) {    
          Id batchJobId = Database.executeBatch(new BatchEmailOptOut());
    }
}