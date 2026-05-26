public class SpamDelete {
    //this method is invoked when a record is inserted into LocalTimeQueue__c
       @InvocableMethod
       public static void deleteSpamCase(List<Id> CaseIds) {
          List<Case> lstC =  [SELECT id FROM Case WHERE Id IN:CaseIds and Origin = 'Web'];
           delete lstC;
       }
   }