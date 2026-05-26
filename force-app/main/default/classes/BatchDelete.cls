public class BatchDelete implements Database.Batchable<sObject> {
   public String query;

   public Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   public void execute(Database.BatchableContext BC, List<sObject> scope){
      
      Database.DeleteResult[] DR_Dels = Database.delete(scope,false);
      DataBase.emptyRecycleBin(scope);
   }

   public void finish(Database.BatchableContext BC){
       System.debug('Batch delete completed');
   }
}