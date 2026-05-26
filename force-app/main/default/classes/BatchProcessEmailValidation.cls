public class BatchProcessEmailValidation implements Database.Batchable<Sobject>,Database.AllowsCallouts {   
    
    List<Contact> updContacts = new List<Contact>();
    List<Practice_Review__c> updPR = new List<Practice_Review__c>();
    
	public Database.QueryLocator start(Database.BatchableContext bc) {
    	String query = 'Select Id, Job_Id__c, Type__c from Email_Validation_Job__c where createddate = Today and Processed_DateTime__c = NULL';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Email_Validation_Job__c> scope){
        List<String> lstFailedEmails = new List<String>();
        
        for(Email_Validation_Job__c evj: scope){ 
            System.debug('Job Id: ' + evj.Job_Id__c);
        	lstFailedEmails = Validator.getValidationJobFailures(evj.Job_Id__c);
        
            System.debug('Failed emails ' + lstFailedEmails);
            if(lstFailedEmails != NULL)
                evj.Processed_DateTime__c = DateTime.now();
            if(lstFailedEmails != NULL && lstFailedEmails.size() > 0){
                System.debug('Inside getting PR records');
                if(evj.Type__c == 'Practice Review')
                    getPracticeReviews(lstFailedEmails);
                else 
                    getContacts(lstFailedEmails);                
             }
        }
        update scope;
        
        if(updContacts.size() > 0)
       		update updContacts;
        if(updPR.size() > 0)
       		update updPR;
        
    }
    
    public void getContacts(List<String> lstFailedEmails){       
       List<Contact> contacts = [Select Id, Email, HasOptedOutOfEmail from Contact where RecordType.name = 'Patient' and email in :lstFailedEmails];
       if(contacts.size() > 0){
            For(Contact con : contacts){
                con.HasOptedOutOfEmail = True; 
                updContacts.add(con);
            }
       }
    }
    
    public void getPracticeReviews(List<String> lstFailedEmails){
        List<Practice_Review__c> lstPracticeReviews = [Select Id, pr_email__c,pr_valid_email__c from Practice_Review__c where pr_email__c in :lstFailedEmails];
        if(lstPracticeReviews.size() > 0){
            For(Practice_Review__c pr: lstPracticeReviews){
                System.debug('PR Email: ' + pr.pr_email__c);
                pr.pr_valid_email__c = False;
                updPR.add(pr);
            }
        }        
    }
    
    public void finish(Database.BatchableContext bc){
       
    }

}