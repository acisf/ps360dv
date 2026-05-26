global class ScheduleUnassignedCasesReport implements Schedulable{
    
    global void execute(SchedulableContext sc){
        UnassignedCasesReport.sendUnassignedCasesReport('IT: Applications Team');
        UnassignedCasesReport.sendUnassignedCasesReport('Purchasing: General Support');
    }

}