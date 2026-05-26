global class ScheduleBatchFBLeads implements Schedulable  {
    
    /*
System.schedule('Facebook Leads Job 0', '0 0 * * * ?', new ScheduleBatchFBLeads());
System.schedule('Facebook Leads Job 1', '0 10 * * * ?', new ScheduleBatchFBLeads());
System.schedule('Facebook Leads Job 2', '0 20 * * * ?', new ScheduleBatchFBLeads());
System.schedule('Facebook Leads Job 3', '0 30 * * * ?', new ScheduleBatchFBLeads());
System.schedule('Facebook Leads Job 4', '0 40 * * * ?', new ScheduleBatchFBLeads());
System.schedule('Facebook Leads Job 5', '0 50 * * * ?', new ScheduleBatchFBLeads());
*/
    
    global void execute(SchedulableContext SC) { 
        BatchFBLeads batch = new BatchFBLeads(); 
        Database.executeBatch(batch, 1); 
        
    }
}