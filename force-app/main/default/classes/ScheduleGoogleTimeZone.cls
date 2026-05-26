global class ScheduleGoogleTimeZone implements Schedulable {
 //System.schedule('Update Local Times','0 0 15 1 1/1 ? *', new ScheduleGoogleTimeZone());

    global void execute(SchedulableContext SC) { 
        Database.executeBatch(new BatchGoogleTimeZone(),10);      
    }
}