global class ScheduleADUserJob implements Schedulable {
    /*
System.schedule('AD User Job','0 11 00 * * ? *',new BatchADUserJob()    
*/
    global void execute(SchedulableContext SC) {    
        DateTime dt = DateTime.newInstance(Date.today(),Time.newInstance(0,0,0,0));
          BatchADUserJob job = new BatchADUserJob(dt);
        	Database.executeBatch(job);
        
        BatchADContactJob job2 = new BatchADContactJob(dt);
        Database.executeBatch(job2);
      
    }
}