global class ScheduleFirstCallResolutionBatch implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        DateTime callEnd = DateTime.newInstance(DateTime.now().year(), DateTime.now().month(), DateTime.now().day(), 0,0,0);
        FirstCallResolutionBatch1 batch = new FirstCallResolutionBatch1(callEnd);
        Database.executeBatch(batch);
    }
}