global class ScheduleCallSummaryJob  implements Schedulable {
    
    //System.schedule('Daily','0 2 0 1/1 * ? *', new cna_ScheduleJob());

    global void execute(SchedulableContext SC) { 
        CallSummaryJob.run();
    }
}