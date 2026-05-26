/*
System.schedule('Patient Match 10a', '0 5 10 * * ? *', new SchedulePatientMatch());
System.schedule('Patient Match 12p', '0 5 12 * * ? *', new SchedulePatientMatch());
System.schedule('Patient Match 2p',  '0 5 14 * * ? *', new SchedulePatientMatch());
System.schedule('Patient Match 4p',  '0 5 16 * * ? *', new SchedulePatientMatch());
System.schedule('Patient Match 6p',  '0 5 18 * * ? *', new SchedulePatientMatch());
System.schedule('Patient Match 8p',  '0 5 20 * * ? *', new SchedulePatientMatch());
System.schedule('Patient Match 10p', '0 5 22 * * ? *', new SchedulePatientMatch());

*/

global class SchedulePatientMatch implements Schedulable { 
    
    global void execute(SchedulableContext SC) { 

        Date dtCreated = Date.today();

        ContactPatientMatchBatch job1 = new ContactPatientMatchBatch(dtCreated);
        Database.executeBatch(job1,100);
        
        BatchFacebookPatientMatch job2 = new BatchFacebookPatientMatch('TODAY');
        DataBase.executeBatch(job2,100); 
        
        LeadPatientMatch job3 = new LeadPatientMatch(dtCreated);
        DataBase.executeBatch(job3,100); 
          

        
    }
}