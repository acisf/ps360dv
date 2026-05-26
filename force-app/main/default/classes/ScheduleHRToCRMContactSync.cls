global class ScheduleHRToCRMContactSync implements Schedulable {

    global void execute(SchedulableContext sc) {

        Date importDate = Date.today(); 

        Database.executeBatch(
            new BatchHRToCRMContactSync(importDate),
            200
        );
    }

}