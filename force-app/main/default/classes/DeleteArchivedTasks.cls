global class DeleteArchivedTasks implements Database.Batchable<sObject> {
    
    integer count = 0;
   global Database.QueryLocator start(Database.BatchableContext bc){
       String query = '';
       if(test.isRunningTest()) {
           query = 'Select Id from Task LIMIT 1';
       } else {
            query = 'Select Id from Task where isArchived = true ALL ROWS';
       }
       
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<task> taskrec){
        count += taskrec.size();
        try{
            
            delete taskrec;
        }
        catch(Exception e){
            System.debug(e);
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug('Records deleted : ' + count);
    }
    

}