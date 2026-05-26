/*
 *  Run on Sunday to get Call Center summaries from Mon - Sat
 * 
*/


global class ScheduleCallCenterKPIJob implements Schedulable {

    global void execute(SchedulableContext sc) {
        Date today = Date.today();

        // Compute previous Monday to Saturday range
        Date startDate = today.addDays(-6);
        Date endDate = today;

        System.debug('Executing scheduled KPI batch for: ' + startDate + ' to ' + endDate);

        // Instantiate and configure the batch
        CallCenterKPIJob.run(startDate,endDate);
    }
}