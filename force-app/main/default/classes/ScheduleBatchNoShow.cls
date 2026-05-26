global with sharing class ScheduleBatchNoShow implements Schedulable {
    global void execute(SchedulableContext sc) {
        BatchNoShow batch = new BatchNoShow(Date.today());
        Database.executeBatch(batch, 200);
    }
}