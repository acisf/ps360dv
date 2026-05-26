public class BatchFBMessengerEmail implements Database.Batchable<sObject> {
    
    public static Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT id,FB_Message_Id__c,Lead__c,Lead__r.Email,FB_Practice__c, FB_Practice__r.FB_Lead_Optin__c, ' +
            'FB_Practice__r.FB_Discount_Optin__c, FB_Practice_Id__c FROM FB_Lead__c ' +
            'WHERE Lead__c !=NULL AND ' +
            'Scheduled__c = 0 AND ' +
            '( (FB_Message_Id__c = 1 AND FB_1st_Contact_Time__c = NULL) OR ' +
            '(FB_Message_Id__c = 2 AND FB_2nd_Contact_Time__c = NULL) OR ' +
            '(FB_Message_Id__c = 3 AND FB_3rd_Contact_Time__c = NULL))';
        
        return Database.getQueryLocator(query);	
    }
    
    public static void execute(Database.BatchableContext bc, List<FB_Lead__c> lstFB){
        OrgWideEmailAddress owa; 
        List<Messaging.SingleEmailMessage> allmsg= new List<Messaging.SingleEmailMessage>();  
        List<String> toAddr;        
        List<EmailTemplate> lstTemplatesCoupon;
        List<EmailTemplate> lstTemplatesNoCoupon;
        List<EmailTemplate> lstTemplatesNoLocation;
        Set<string> templateCoupon = new Set<String> {'FB1','FB2','FB3'};
        Set<string> templatesNoCoupon = new Set<String> {'FB1','FB2NoCoupon','FB3NoCoupon'};
        Set<string> templatesNoLocation = new Set<String> {'FB1NoLocation','FB2NoLocation','FB3NoLocation'};                    
        Messaging.SingleEmailMessage mail;        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'patientsupport@affordablecare.com'];        
        lstTemplatesCoupon = [Select id,name from EmailTemplate where name in: templateCoupon ORDER BY name];       
        lstTemplatesNoCoupon = [Select id,name from EmailTemplate where name in: templatesNoCoupon ORDER BY name];
        lstTemplatesNoLocation = [Select id,name from EmailTemplate where name in: templatesNoLocation ORDER BY name];
        
        for(FB_Lead__c fb:lstFB) {
            //instantiate mail, assign template based on message id
            Integer x = (Integer)fb.FB_Message_Id__c;
            mail = new Messaging.SingleEmailMessage();
            toAddr = new List<String>(); 
            toAddr.add(fb.Lead__c);
            mail.optoutpolicy='FILTER';
            mail.setUseSignature(false);
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            mail.setBCCSender(false);
            mail.toaddresses = toaddr;
            mail.setWhatId(fb.id);
            mail.setTargetObjectId(fb.Lead__c);   
            
            //set template based on whether the practice exists and offers coupons  
            if(fb.FB_Practice__c == null)
                mail.setTemplateId(lstTemplatesNoLocation.get(x-1).id);          
            else if(fb.FB_Practice__r.FB_Discount_Optin__c)
                mail.setTemplateId(lstTemplatesCoupon.get(x-1).id);  
            else
                mail.setTemplateId(lstTemplatesNoCoupon.get(x-1).id);      
            
            allmsg.add(mail);   
        
            //assign timestamp to track mail send
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