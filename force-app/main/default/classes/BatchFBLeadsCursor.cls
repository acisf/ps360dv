public class BatchFBLeadsCursor implements Database.Batchable<sObject>, Database.AllowsCallouts{
 
    public static Database.QueryLocator start(Database.BatchableContext bc){
       
        string query = 'SELECT Id,Form_Id__c,FB_After_Cursor__c,Debug_String__c, FB_From_Date__c, Active__c' +
        ' FROM Facebook_Form__c WHERE Active__c = true And FB_After_Cursor__c != \'\'' +
        ' ORDER BY NAME';
    
        return Database.getQueryLocator(query);
    }
    
    public static void execute(Database.BatchableContext bc, List<Facebook_Form__c> forms){
        
        for(Facebook_Form__c form: forms){            
            AutoFBLeads.downloadLeads(form);
        }
        
    }
    
    public static void finish(Database.BatchableContext bc){
        
         List<Facebook_Form__c> lstFormsWithoutAfterCursors;
        List<Facebook_Form__c> lstFormsWithAfterCursors;        
        
        lstFormsWithoutAfterCursors = [Select id, FB_From_Date__c
                                    from Facebook_form__c 
                                    where active__c = true 
                                    and fb_after_cursor__c = ''];
        
        lstFormsWithAfterCursors = [Select id 
                                    from Facebook_form__c 
                                    where active__c = true 
                                    and fb_after_cursor__c != ''];
        
        //fb_EmailJob.sendNotificationToPractice(); 
        
 		for(Facebook_Form__c fb:lstFormsWithoutAfterCursors ) {
            fb.FB_From_Date__c = Date.today() - 1;
        }
        
        update lstFormsWithoutAfterCursors; 
    
        if(lstFormsWithAfterCursors.size() > 0 ) {
            Database.executeBatch(new BatchFBLeadsCursor(), 1); 
        }

    }
}