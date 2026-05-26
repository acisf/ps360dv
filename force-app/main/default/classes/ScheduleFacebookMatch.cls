/*
System.schedule('Facebook-Appt 10a', '0 5 10 * * ? *', new ScheduleFacebookMatch());
System.schedule('Facebook-Appt 12p', '0 5 12 * * ? *', new ScheduleFacebookMatch());
System.schedule('Facebook-Appt 2p',  '0 5 14 * * ? *', new ScheduleFacebookMatch());
System.schedule('Facebook-Appt 4p',  '0 5 16 * * ? *', new ScheduleFacebookMatch());
System.schedule('Facebook-Appt 6p',  '0 5 18 * * ? *', new ScheduleFacebookMatch());
System.schedule('Facebook-Appt 8p',  '0 5 20 * * ? *', new ScheduleFacebookMatch());

*/

global class ScheduleFacebookMatch implements Schedulable { 
    
    global void execute(SchedulableContext SC) { 
        
        BatchFacebookPatientMatch obj = new BatchFacebookPatientMatch('TODAY');
        DataBase.executeBatch(obj,50); 
        
    }
}