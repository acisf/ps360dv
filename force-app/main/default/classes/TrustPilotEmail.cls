public class TrustPilotEmail implements Database.Batchable<sobject> {
    //Emails are sent at 1pm 1st and 15th
    // System.schedule('TrustPilot Email','0 0 13 1,2,3,15,16,17 * ? *',new schedule_pr_emailJob());
    
    public List<practice_review__c> lstPR; 
    
    public Database.QueryLocator start (Database.BatchableContext bc) {
        
        String sql = 'SELECT Id,Name,pr_Account__c,pr_brand_name__c,pr_city_state_zip__c,' +
            'pr_Contact__c, pr_date_of_service__c,pr_email__c, pr_first_name__c, ' +
            'pr_last_name__c, pr_practice_id__c, pr_practice_id_5__c, pr_review_url__c, ' +
            'pr_date_sent__c,pr_valid_email__c FROM practice_review__c WHERE ' +
            'CreatedDate = last_n_days:15 AND pr_valid_email__c = true AND pr_date_sent__c = null limit 5000';
        return Database.getQueryLocator(sql);
    }
    public void execute(Database.BatchableContext bc, list<practice_review__c> scope) {
        Validator.setTopLevelDomains();
        lstPR = new List<practice_review__c>();
        lstPR.addAll(scope);
        matchAccounts();       
        matchContacts();
        sendMessage();        
    }
    
        
    public void matchAccounts() {
        
        List<Account> lstAccount;
        set<string> accounts = new set<string>();
        map<string,id> accountmap = new map<string,id>();
        
        for(practice_review__c pr:lstPR) {
            accounts.add(pr.pr_practice_id_5__c);
        }
        
        lstAccount = [SELECT Id,location_Id_5_digit__c,location_id__c
                      FROM Account 
                      WHERE location_Id_5_digit__c in: accounts];
        
        for(account a: lstAccount) {
            accountmap.put(a.location_Id_5_digit__c,a.id);
        }
        
        for(practice_review__c pr: lstPR) {
            if(accountmap.get(pr.pr_practice_id_5__c)!= null) {
                pr.pr_Account__c = accountmap.get(pr.pr_practice_id_5__c);
            }
        }
        
        update lstPR;        
        
    }
    
    public void matchContacts() {
        
        List<Contact> lstContact;
        set<string> emails = new set<string>();
        map<string,id> contactmap = new map<string,id>();
        map<string,practice_review__c> premailmap = new map<string,practice_review__c>();
        
        //unique set of emails
        for(practice_review__c pr:lstPR) {
            emails.add(pr.pr_email__c);
            premailmap.put(pr.pr_email__c,pr);
        }
        
        //get contacts by email        
        lstContact = [SELECT id,email,firstname,lastname,description,accountid
                      FROM contact WHERE email in: emails];
        
        //if missing account id, get from practice_review
        for(Contact c:lstContact) {
            if(c.AccountId == null) {
                if( premailmap.get(c.email)!=null) {
                    c.AccountId = premailmap.get(c.email).id;
                }
            }
            
        }   
        
        //create email to contact map
        for(Contact c:lstContact) {
            if(c.AccountId != null) {
                contactmap.put(c.email,c.id);
            }
        }     
        
        //if contact not found create it
        for(practice_review__c pr:lstPR) {
            if(contactmap.get(pr.pr_email__c) == null && pr.pr_valid_email__c) {
                Contact c = new Contact();
                c.AccountId =  pr.pr_Account__c;
                c.Email = pr.pr_Email__c; 
                c.FirstName = pr.pr_first_name__c;
                c.LastName = pr.pr_last_name__c; 
                c.Description = 'Practice Review email';
                lstContact.add(c); 
            }
        }
        
        //upsert contacts
        Database.UpsertResult[] srList = Database.upsert(lstContact, false);
        
        //build contact map
        for(Contact c:lstContact) {
            contactmap.put(c.email,c.id);
        }       
        
        //update contact field in practice_review
        for(practice_review__c pr:lstPR) {
            if(contactmap.get(pr.pr_email__c)!=null) {
                pr.pr_Contact__c = contactmap.get(pr.pr_email__c);
            }
        }
        
        //upsert contacts
        Database.SaveResult[] ulist = Database.update(lstPR, false);
        
    }
    
    public void sendMessage() { 
        
        OrgWideEmailAddress owa;       
        List<Messaging.SingleEmailMessage> allmsg; 
        List<EmailTemplate> lstTemplates;      
        Messaging.SingleEmailMessage mail; 
        Set<Id> contacts = new Set<Id>();
        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'patientsupport@affordablecare.com'];        
        lstTemplates = [Select id,name from EmailTemplate where name like 'Trustpilot' ORDER BY Name];                
        allmsg =new List<Messaging.SingleEmailMessage>();  
        
        //instantiate mail objects and timestamp tracking objects
        for(practice_review__c pr:lstPR) {      
                mail = new Messaging.SingleEmailMessage(); 
                mail.optoutpolicy='FILTER';
                mail.setUseSignature(false);
                
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                
                mail.setBCCSender(false); 
                mail.setTargetObjectId(pr.pr_Contact__c); 
                mail.setWhatId(pr.id); 
                mail.setTemplateId(lstTemplates.get(0).id);             
                mail.setSaveAsActivity(true);
                
                if(contacts.add(pr.pr_Contact__c)){
                	allmsg.add(mail);
                }
                
                pr.pr_date_sent__c = Date.today();
            
        }
        
        //send emails
        Messaging.sendEmail(allmsg,false);
        
        //timestamp tracking objects
        update lstPR;  
        
    }
    
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Trustpilot Survey completed successfully');
    }
    
}