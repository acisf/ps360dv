global class ScheduleBatchFBLeadToZeta implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchFBLeadToZeta(), 200);
    }
}