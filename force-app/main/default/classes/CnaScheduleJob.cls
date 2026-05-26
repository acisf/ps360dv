global class CnaScheduleJob  implements Schedulable {
    
    //System.schedule('Daily','0 1 0 1/1 * ? *', new cna_ScheduleJob());

    global void execute(SchedulableContext SC) { 
       
        //testing only remove before rolling out
        //zeta_data.testData();
        //end testing only
            
        CnaJob.tracking();
        /*CnaJob.appointed(); 
        CnaJob.emailoptouts(); 
        CnaJob.robocalloptouts();
        CnaJob.truncateExistingPatientTemp();*/
        
         List<NVMStatsSF__NVM_Call_Summary__c>lstCNACallsTemp; 
       
        
    }
}