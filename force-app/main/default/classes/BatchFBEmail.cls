public class BatchFBEmail implements Database.Batchable<sObject> {
    
    public static Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT id,FB_Message_Id__c,FB_Contact__c,FB_Contact__r.Email,FB_Practice__c, FB_Practice__r.FB_Lead_Optin__c, FB_Practice__r.FB_Discount_Optin__c, FB_Practice_Id__c FROM FB_Lead__c WHERE (FB_Practice_Id__c = \'99999\' OR (FB_Practice__r.FB_Lead_Optin__c = TRUE AND FB_Practice__r.FB_Email_campaign_opt_in__c = TRUE)) AND Scheduled__c = 0 AND FB_Form__c != NULL ' +
            'AND ( (FB_Message_Id__c = 1 AND FB_1st_Contact_Time__c = NULL) OR (FB_Message_Id__c = 2 AND FB_2nd_Contact_Time__c = NULL) OR (FB_Message_Id__c = 3 AND FB_3rd_Contact_Time__c = NULL) )';
        
        return Database.getQueryLocator(query);
    }
    
    public static void execute(Database.BatchableContext bc, List<FB_Lead__c> lstFB){
        OrgWideEmailAddress owa; 
        List<Messaging.SingleEmailMessage> allmsg= new List<Messaging.SingleEmailMessage>();  
        List<String> toAddr;        
        List<EmailTemplate> lstTemplatesCoupon;
        List<EmailTemplate> lstTemplatesNoCoupon;
        List<EmailTemplate> lstTemplatesNoLocation;
        List<EmailTemplate> lstTemplatesPromo;
        Set<string> templateCoupon = new Set<String> {'FB1','FB2','FB3'};
            Set<string> templatesNoCoupon = new Set<String> {'FB1','FB2NoCoupon','FB3NoCoupon'};
                Set<string> templatesNoLocation = new Set<String> {'FB1NoLocation','FB2NoLocation','FB3NoLocation'};
                    
                    Messaging.SingleEmailMessage mail;        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'patientsupport@affordablecare.com'];        
        lstTemplatesCoupon = [Select id,name from EmailTemplate where name in: templateCoupon ORDER BY name];       
        lstTemplatesNoCoupon = [Select id,name from EmailTemplate where name in: templatesNoCoupon ORDER BY name];
        lstTemplatesNoLocation = [Select id,name from EmailTemplate where name in: templatesNoLocation ORDER BY name];        
        lstTemplatesPromo = [Select id,name from EmailTemplate where name = 'FBPromo' ORDER BY name];
        
        Validator.setTopLevelDomains();
        
        for(FB_Lead__c fb:lstFB) {
            Integer x = (Integer)fb.FB_Message_Id__c;
            mail = new Messaging.SingleEmailMessage();
            toAddr = new List<String>(); 
            toAddr.add(fb.FB_Contact__c);
            mail.optoutpolicy='FILTER';
            mail.setUseSignature(false);
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            mail.setBCCSender(false);
            mail.toaddresses = toaddr;
            mail.setWhatId(fb.id);
            mail.setTargetObjectId(fb.fb_Contact__c);   
            
            //set template based on whether the practice is selected and selected practices offers coupons  
            if(fb.FB_Practice_Id__c == '92001')
                mail.setTemplateId(lstTemplatesNoLocation.get(x-1).id);          
            else if(fb.FB_Practice__r.FB_Discount_Optin__c)
                mail.setTemplateId(lstTemplatesCoupon.get(x-1).id);  
            else
                mail.setTemplateId(lstTemplatesNoCoupon.get(x-1).id);     
            
            //NDWP promo 7/8/24
            if (x==1 && 
                Date.today() >= Date.newInstance(2024,7,8) &&
                Date.today() <= Date.newInstance(2024,7,30) &&
                fb.FB_Practice_Id__c != '08030' &&
                fb.FB_Practice_Id__c != '20124' &&
                fb.FB_Practice_Id__c != '20254' &&
                fb.FB_Practice_Id__c != '20332' &&
                fb.FB_Practice_Id__c != '20270' &&
                fb.FB_Practice_Id__c != '27148')
            {
                mail.setTemplateId(lstTemplatesPromo.get(0).id);
            }
            
            //validate email
            boolean valid = false;
            valid = Validator.isValidEmail(fb.fb_Contact__r.Email) && 
                Validator.hasValidTopLevelDomain(fb.fb_Contact__r.Email);
            Validator.hasValidDomain(fb.FB_Contact__r.Email);
            
            if(valid) {
                allmsg.add(mail);   
            }     
            
            if(x==1)
                fb.FB_1st_Contact_Time__c = Date.today();
            else if (x==2) 
                fb.FB_2nd_Contact_Time__c = Date.today();
            else if (x==3) 
                fb.FB_3rd_Contact_Time__c = Date.today();
        }
        
        //send emails
        Messaging.sendEmail(allmsg,false);
        
        //timestamp tracking objects
        update lstFb;  
        
    }
    
    public static void finish(Database.BatchableContext bc){
    }
    
}