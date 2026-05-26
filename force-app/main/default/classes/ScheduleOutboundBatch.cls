public class ScheduleOutboundBatch implements Schedulable {
    public void execute(SchedulableContext sc) {
        BatchProcessTmp batch = new BatchProcessTmp();
        Database.executeBatch(batch);
    }
}