public class CallSummaryJob {
    
    public static DateTime startdate = DateTime.newInstance(Date.today()-1, Time.newInstance(0,0,0,0)); 
    public static DateTime enddate = DateTime.newInstance(Date.today(), Time.newInstance(0,0,0,0)); 
    public static List<NVMStatsSF__NVM_Call_Summary__c>lstScheduled = new List<NVMStatsSF__NVM_Call_Summary__c>(); 
    
    @future
    public static void run() {  	
        updatePracticeMatch();
    }
    
    public static void updatePracticeMatch() {   
        //Debugging
        System.debug('Start Date:'+ startdate);
        System.debug('End Date:'+ enddate);

        //calls scheduled or re-scheduled
        lstScheduled = [SELECT Id, NVMStatsSF__CallTime__c, Service_Name_Practice__c, 
                        NVMStatsSF__Related_To__c,NVMStatsSF__CallDisposition__c,Service_Practice_Match__c
                        FROM NVMStatsSF__NVM_Call_Summary__c 
                        WHERE NVMStatsSF__Interaction_Type__c = 'Inbound Call'
                        AND NVMStatsSF__CallTime__c >=: startdate
                        AND NVMStatsSF__CallTime__c <: enddate
                        AND Service_Name_Practice__c !=: '800 DENTURES'
                        AND (NVMStatsSF__CallDisposition__c =: 'Scheduled' OR
                             NVMStatsSF__CallDisposition__c =: 'Rescheduled')
                        ORDER BY NVMStatsSF__CallTime__c DESC ];
        //Debugging
        System.debug('Records Retrieved: '+ lstScheduled.size());
        
        for(NVMStatsSF__NVM_Call_Summary__c call:lstScheduled) {
            if(call.NVMStatsSF__Related_To__c!=null) {
                 
                if(call.NVMStatsSF__Related_To__c.replace('.','').tolowercase().indexOf(call.Service_Name_Practice__c.replace('N ','North ').replace('E ','East ').tolowercase()) != -1) {
                    call.Service_Practice_Match__c = true;
                }
                
                if(call.NVMStatsSF__Related_To__c == 'Phoenix - Arizona' && 
                   call.Service_Name_Practice__c == 'Phoenix Sun City' ) {
                       call.Service_Practice_Match__c = true;
                   }
                
            }
        }
        
        Database.SaveResult[] sr = Database.update(lstScheduled,false); 
        System.debug('Save Result');
        system.debug(sr);
        
    } 
    
    
}