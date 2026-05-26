public class BatchContactEmailOptOut implements Database.Batchable<Sobject>,Database.AllowsCallouts {
    public static List<Contact> lstContacts = new List<Contact>();

	public Database.QueryLocator start(Database.BatchableContext bc) {
    	String query = 'Select Id, Job_Id__c from Email_Validation_Job__c where createddate = Today and Processed_DateTime__c = NULL';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Email_Validation_Job__c> scope){
        List<String> lstFailedEmails = new List<String>();
        List<Contact> updContacts = new List<Contact>();
        for(Email_Validation_Job__c evj: scope){            
        	lstFailedEmails = Validator.getValidationJobFailures(evj.Job_Id__c);
        
            System.debug('Failed emails ' + lstFailedEmails);
            if(lstFailedEmails != NULL)
                evj.Processed_DateTime__c = DateTime.now();
            if(lstFailedEmails != NULL && lstFailedEmails.size() > 0){                           	                                                              
                List<Contact> contacts = [Select Id, Email, HasOptedOutOfEmail from Contact where RecordType.name = 'Patient' and email in :lstFailedEmails];
                if(contacts.size() > 0){
            		For(Contact con : contacts){
                		con.HasOptedOutOfEmail = True; 
                        updContacts.add(con);
            		}
        		}
            }
        }
        update scope;
        if(updContacts.size() > 0)
            update updContacts;
    }
    
    public void finish(Database.BatchableContext bc){
       
    }
    
}