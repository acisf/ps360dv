global class ScheduleSubmitEmailValidation implements Schedulable{
    
    global void execute(SchedulableContext SC) {   
        
        BatchSubmitEmailValidation obj1 = new BatchSubmitEmailValidation('Facebook');
        DataBase.executeBatch(obj1,250);
        
        BatchSubmitEmailValidation obj2 = new BatchSubmitEmailValidation('Practice Review');        
        DataBase.executeBatch(obj2,250);
        
    }
    
}