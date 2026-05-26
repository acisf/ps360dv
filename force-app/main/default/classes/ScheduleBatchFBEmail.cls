global class ScheduleBatchFBEmail implements Schedulable { 
    
    global void execute(SchedulableContext SC) { 
        Database.executeBatch(new BatchFBEmail(), 25);
        Database.executeBatch(new BatchFBMessengerEmail(), 25);
    }
}