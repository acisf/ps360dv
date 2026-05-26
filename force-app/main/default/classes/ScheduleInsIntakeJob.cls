global class ScheduleInsIntakeJob implements Schedulable {

    global void execute(SchedulableContext SC) { 
        if(DateTime.now().hour() < 14) {
        	InsIntakeJob.runReports(0);
         }
        else { 
            InsIntakeJob.runReports(1);
    	}
	}
}