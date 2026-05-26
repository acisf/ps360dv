public class NotificationEmail {
    
    // AA - Bug fix 4/28/2026 
    private static final String REPLY_TO_ADDRESS = 'casereply@affordablecare.com';
    // AA - Bug fix 4/28/2026
   
    
    public static OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'new-case@affordablecare.com'];       
    public static EmailTemplate autoResponseTemplate = [Select Id from EmailTemplate where name = 'MyPractice General' limit 1];   
    
    @InvocableMethod(label='Send Notification Email ')
    public static void sendNotificationEmail(List<ID> ids){      
        
        List<Case> cases;
        List<String> toAddr; 
        List<String> ccAddr; 
        List<String> bccAddr;
        Messaging.SingleEmailMessage mail;        
        List<Messaging.SingleEmailMessage> allmsg;
        
        List<String> emailAddr = new List<String>();        
        Map<String,Id> mapContact = new Map<String,Id>();   
        
        cases = [Select Id, Contact.Id, Contact.Email, Contact.Alt_Email__c, SuppliedEmail, Team__c, Category__c, 
                 IsCreatedInConsole__c, Origin,
                 Description, Contact.Name,
                 Account.Name,Account.Address__c,Account.Location_ID_5_Digit__c,Room_Number__c,Account.Phone
                 from Case where Id in :ids]; 
        
        allmsg = new List<Messaging.SingleEmailMessage>();  
        
        emailAddr = getWebEmailForNullContacts(cases,emailAddr);                              
        mapContact = getContactDetailsForNullContacts(emailAddr,mapContact);
        
        for(Case c:cases){
            
            if(c.Team__c == 'Dental Equipment Repairs')   
                allmsg = sendEmailToHenryScheinForRepairsCases(c,allmsg,toAddr,ccAddr, bccAddr, mail);
            
            if(c.IsCreatedInConsole__c || c.Origin == 'MyPractice')
                allmsg = sendAutoResponseForManuallyCreatedCases(c,allmsg,toAddr,ccAddr,bccAddr,mail,mapContact);
        }
        
        Messaging.sendEmail(allmsg,false);        
    }
    
    public static List<String> getWebEmailForNullContacts(List<Case> cases, List<String> emailAddr){
        for(Case c: cases){
            if (c.contact.Id == null  && c.SuppliedEmail != null){
                emailAddr.add(c.SuppliedEmail);     
            }  
        }
        return emailAddr;
    }
    
    public static Map<String,Id> getContactDetailsForNullContacts(List<String> emailAddr,Map<String,Id> mapContact){
        if(emailAddr.size() > 0){
            List<Contact> contact = [Select Id, email,alt_email__c from contact where email in :emailAddr
                                     AND (Contact.Recordtype.Name = 'Practice Employee' OR Contact.Recordtype.Name = 'Corporate Employee')];
            for(Contact con: contact)
                mapContact.put(con.email,con.Id);
        }
        return mapContact;
    }
    
    public static List<Messaging.SingleEmailMessage> sendEmailToHenryScheinForRepairsCases(Case c,List<Messaging.SingleEmailMessage> allmsg,List<String> toAddr,List<String> ccAddr,List<String> bccAddr,Messaging.SingleEmailMessage mail){    
        mail = new Messaging.SingleEmailMessage();
        toAddr = new List<String>();
        ccAddr = new List<String>();
        bccAddr = new List<String>();                                                                                       
        
        if(c.Category__c == 'Large Equipment'){
            toAddr.add('NDSOHelpDesk@henryschein.com');   
            bccAddr.add('douglas.vann@affordablecare.com');
        }
        
        else if(c.Category__c == 'Small Equipment' || c.Category__c == 'Handpiece'){
            toAddr.add('prorepair@henryschein.com');            
            bccAddr.add('douglas.vann@affordablecare.com');
        }                                                      
        
        mail = composeEmail(c,mail);
        mail = sendEmail(c,toAddr,ccAddr,bccAddr,mail);  
        allmsg.add(mail);              
        
        return allmsg;
    }
    
    public static Messaging.SingleEmailMessage sendEmail(Case c,List<String> toAddr,List<String> ccAddr,List<String> bccAddr,Messaging.SingleEmailMessage mail){
        mail.optoutpolicy='FILTER';
        mail.setUseSignature(false);
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        
        if(c.Contact.Id != null && c.Contact.Email != NULL) {
            toAddr.add(c.Contact.Email);
            if (String.isNotBlank(c.Contact.Alt_Email__c)) {
    			toAddr.add(c.Contact.Alt_Email__c.trim());
			}
        }
        else{
            if(c.SuppliedEmail != NULL)                         
                toAddr.add(c.SuppliedEmail);                       
        } 
        mail.setBCCSender(false);
        mail.toaddresses = toAddr;
        mail.bccaddresses = bccAddr;
        mail.setWhatId(c.id);
        return mail;        
    }
    
    public static List<Messaging.SingleEmailMessage> sendAutoResponseForManuallyCreatedCases(Case c,List<Messaging.SingleEmailMessage> allmsg,List<String> toAddr,List<String> ccAddr, List<String> bccAddr,Messaging.SingleEmailMessage mail,Map<String,Id> mapContact){
        mail = new Messaging.SingleEmailMessage();
        toAddr = new List<String>();
        ccAddr = new List<String>();
        bccAddr = new List<String>();
        
        mail = sendEmail(c,toAddr,ccAddr, bccAddr, mail);
        
        // AA - Bug fix 4/28/2026
        mail.setReplyTo(REPLY_TO_ADDRESS);
        // AA - Bug fix 4/28/2026
        
        if(c.Contact.Id != null)
            mail.setTargetObjectId(c.Contact.Id);   
        else{
            if(mapContact.size() > 0)                         
                mail.setTargetObjectId(mapContact.get(c.SuppliedEmail));                       
        }
        
        if (autoResponseTemplate != null ) 
            mail.setTemplateId(autoResponseTemplate.Id);
        
        allmsg.add(mail);
        
        return allmsg;        
    }
    
    public static Messaging.SingleEmailMessage composeEmail(Case c, Messaging.SingleEmailMessage mail){
        String strHTML = '';
        String strSubject = 'Equipment Repair Request';       
        
        strHTML = 'Issue Description: ' + c.Description + '<br/><br/>' ;
        strHTML += 'Practice Name: ' + c.Account.Name + '<br/>';
        strHTML += 'Address: ' + c.Account.Address__c + '<br/>';
        strHTML += 'Practice ID: ' + c.Account.Location_ID_5_Digit__c + '<br/>';
        strHTML += 'Room Number: ' + c.Room_Number__c + '<br/>';
        strHTML += 'Name: ' + c.Contact.Name + '<br/>';
        strHTML += 'Phone: ' + c.Account.Phone + '<br/>';
        strHTML += 'Email: ' + c.Contact.Email + '<br/>';
        strHTML += '<br/><br/><br/><br/><br/><br/>';
        strHTML += 'NOTE: Use Reply All to include all recipients. It is not recommended that you forward this email because its association with the original case may be lost.';
        
        mail.setSubject(strSubject);
        mail.setHtmlBody(strHTML);
        mail.setPlainTextBody(strHTML.stripHtmlTags());
        
        return mail;
    }
}