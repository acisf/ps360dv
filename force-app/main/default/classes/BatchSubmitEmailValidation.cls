public class BatchSubmitEmailValidation implements Database.Batchable<Sobject>,Database.AllowsCallouts {
    
    string type;
    List<Practice_Review__c> lstPRS = new List<Practice_Review__c>();
    
    public BatchSubmitEmailValidation(String name){
        type = name;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        if(type == 'Practice Review')
            query = 'SELECT Id,Name,pr_Account__c,pr_brand_name__c,pr_city_state_zip__c,' +
            'pr_Contact__c, pr_date_of_service__c,pr_email__c, pr_first_name__c, ' +
            'pr_last_name__c, pr_practice_id__c, pr_practice_id_5__c, pr_review_url__c, ' +
            'pr_date_sent__c,pr_valid_email__c FROM practice_review__c WHERE pr_date_sent__c = null and pr_valid_email__c=false and createddate = last_n_days:7';
        else
            query = 'Select Id, FB_Email__c from FB_Lead__c where FB_Scheduled_1__c = Today and Scheduled__c = 0 and HasOptedOut__c = False and FB_Email__c != NULL';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        List<String> lstEmails = new List<String>();
        String jbId;
        
        lstEmails = getEmailList(scope);   

        if(lstEmails.size() > 0)
            wait(2);
            jbId = Validator.submitValidationJob(lstEmails);                                
            createEmailValidationJob(jbId,lstEmails);
        
        if(lstPRS.size() > 0)
            update lstPRS;     
    }

    private void wait(integer s) {
        datetime endTime = System.now().addSeconds(s);
        while(System.now() < endTime) {
        }
    }
    
    public List<String> getEmailList(List<Sobject> scope){
        List<Practice_Review__c> lstPR;  
        List<FB_Lead__c> lstFB;
        List<string> lstEmail = new List<string>();
        Boolean valid;
        
        if(type == 'Practice Review'){
            lstPR = (List<Practice_Review__c>) scope;
            Validator.setTopLevelDomains();
            for(Practice_Review__c pr: lstPR){             
                lstEmail.add(pr.pr_email__c);                                
                valid = Validator.isValidEmail(pr.pr_email__c) && 
                        Validator.hasValidTopLevelDomain(pr.pr_email__c) && 
                        Validator.hasValidDomain(pr.pr_email__c);                
                pr.pr_valid_email__c = valid;               
                lstPRS.add(pr);
            }
        }
        else{
            lstFB = (List<FB_Lead__c>) scope;
            for(FB_Lead__c fb: lstFB) {
                lstEmail.add(fb.FB_Email__c);
            }
        } 
        
        return lstEmail;
    }
    
    public void createEmailValidationJob(String jbId, List<String> lstEmails){
        Email_Validation_Job__c evj = new Email_Validation_Job__c();
        evj.Job_Id__c = jbId;            
        evj.Submission_DateTime__c = DateTime.now();
        if(type == 'Facebook')
            evj.Type__c = 'Facebook';
        else
            evj.Type__c = 'Practice Review';
        if(String.isBlank(jbId))
            evj.List_of_Failed_Emails__c = String.join(lstEmails,',');
        insert evj; 
    }
    
    public void finish(Database.BatchableContext bc){      
        String jobname = 'Process Email Validation ' + type;
        BatchProcessEmailValidation bpe = new BatchProcessEmailValidation();
        system.scheduleBatch(bpe,jobname, 5,1);        
    }  
}