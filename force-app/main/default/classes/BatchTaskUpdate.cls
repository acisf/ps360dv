global class BatchTaskUpdate implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = '';
        if (Test.isRunningTest()) {
             query = 'Select id,(Select id, TaskId, Whoid, LastModifiedDate,firstopendate, lastopendate, timesopened, createddate from EmailStatuses'
                       + ' where EmailTemplateName In (\'FB1\', \'FB2\', \'FB3\',\'FB2NoCoupon\',\'FB3NoCoupon\')) from Contact'
                       + ' WHERE Id IN (SELECT FB_Contact__c FROM FB_Lead__c WHERE LastModifiedDate >= TODAY) LIMIT 10';
        }
        else {
             query = 'Select id,(Select id, TaskId, Whoid, LastModifiedDate,firstopendate, lastopendate, timesopened, createddate from EmailStatuses'
                       + ' where EmailTemplateName In (\'FB1\', \'FB2\', \'FB3\',\'FB2NoCoupon\',\'FB3NoCoupon\')) from Contact'
                       + ' WHERE Id IN (SELECT FB_Contact__c FROM FB_Lead__c WHERE LastModifiedDate = LAST_n_DAYS:30)';
        }
        
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext bc, List<Contact> con){
        try{
        List<Task> tsk = new List<Task>();
        
        For(Contact c: con){
            For(EmailStatus e: c.EmailStatuses){
                Task tsk1 = new Task();
                tsk1.id = e.TaskId;
                tsk1.Number_of_Times_Opened__c = e.Timesopened;
                tsk1.First_Opened_Date__c = e.firstopendate;
                tsk1.Last_Opened_Date__c = e.lastopendate;
                tsk.add(tsk1);
            }
        }
        
        //update tsk;
        Database.SaveResult[] srList = Database.update(tsk, false);
             
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        catch(Exception e){
            System.debug(e.getMessage());
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        
    }

}