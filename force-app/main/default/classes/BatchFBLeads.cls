public class BatchFBLeads implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Form_Id__c, FB_After_Cursor__c, Debug_String__c, FB_From_Date__c, Active__c ' +
            'FROM Facebook_Form__c ' +
            'WHERE Active__c = true ' +
            'ORDER BY LastModifiedDate ASC '
        );
    }
    
    public void execute(Database.BatchableContext bc, List<Facebook_Form__c> forms) {
        for (Facebook_Form__c form : forms) {
            AutoFBLeads.downloadLeads(form);
        }
    }
    
    private void wait(integer s) { datetime endTime = System.now().addSeconds(s); while(System.now() < endTime) { } }
    
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
        
        
        for(Facebook_Form__c fb:lstFormsWithoutAfterCursors ) {
            fb.FB_From_Date__c = Date.today() - 1;
        }
        
        update lstFormsWithoutAfterCursors;        
        
        if(lstFormsWithAfterCursors.size() > 0 ) {
            Database.executeBatch(new BatchFBLeadsCursor(), 1); 
        }
        
        FBPracticeNotifier.sendFBFormLeadsNotification();
        FBPracticeNotifier.sendFBMessengerLeadsNotification();
        FBPracticeNotifier.sendSMSNotifications();
        
    } 
}