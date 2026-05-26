global class ScheduleBatchPracticeInfoRequests implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        BatchPracticeInfoRequests batch = new BatchPracticeInfoRequests();
        Database.executeBatch(batch, 200);
    }
}