public class ScheduleBatchAceBacklog implements Schedulable {
    
    public static Date backlogDate = Date.today(); 

    public void execute(SchedulableContext sc) {
        BatchAceBacklog batch = new BatchAceBacklog(backlogDate);
        Database.executeBatch(batch);
    }
}