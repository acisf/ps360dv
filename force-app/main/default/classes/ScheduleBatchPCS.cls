global class ScheduleBatchPCS implements Schedulable {
    global void execute(SchedulableContext sc) {
        BatchPCS batchJob = new BatchPCS();
        Database.executeBatch(batchJob);
    }
}