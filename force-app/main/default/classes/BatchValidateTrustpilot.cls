public class BatchValidateTrustpilot implements Database.Batchable<sobject> {
    //Emails are sent at 1pm 1st and 15th
    // System.schedule('TrustPilot Email','0 0 13 1,2,3,15,16,17 * ? *',new schedule_pr_emailJob());
    
    public List<practice_review__c> lstPR; 
    
    public Database.QueryLocator start (Database.BatchableContext bc) {
        
        String sql = 'SELECT Id,Name,pr_Account__c,pr_brand_name__c,pr_city_state_zip__c,' +
            'pr_Contact__c, pr_date_of_service__c,pr_email__c, pr_first_name__c, ' +
            'pr_last_name__c, pr_practice_id__c, pr_practice_id_5__c, pr_review_url__c, ' +
            'pr_date_sent__c,pr_valid_email__c FROM practice_review__c WHERE pr_date_sent__c = null';
        return Database.getQueryLocator(sql);
    }
    public void execute(Database.BatchableContext bc, list<practice_review__c> scope) {
        Validator.setTopLevelDomains();
        lstPR = new List<practice_review__c>();
        lstPR.addAll(scope);
        validateEmails();
           
    }
    
    public void validateEmails() {
        
        set<string> emails = new set<string>();
        
        list<emaillog__c> lstEmailLog = [select id,email__c from emaillog__c];

        for(emaillog__c em:lstEmailLog) {
            emails.add(em.email__c);
        }
        for(practice_review__c pr:lstpr) {
            
            boolean valid = Validator.isValidEmail(pr.pr_email__c) && 
                Validator.hasValidTopLevelDomain(pr.pr_email__c) && 
                Validator.hasValidDomain(pr.pr_email__c);
            
            if(emails.contains(pr.pr_email__c)) {
                valid = false;
            }
            
            pr.pr_valid_email__c = valid;
        }
        
        update lstPR;
    }
    public void finish(Database.BatchableContext bc) {
        System.debug('Trustpilot Survey completed successfully');
    }
    
}