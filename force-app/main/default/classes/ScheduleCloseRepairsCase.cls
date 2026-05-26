global class ScheduleCloseRepairsCase implements Schedulable{
    
    global void execute(SchedulableContext sc){
        CloseRepairsCase.autoCloseRepairsCase();
    }

}