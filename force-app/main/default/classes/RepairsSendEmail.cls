public class RepairsSendEmail {
    
    @InvocableMethod(label='Send Email to Henry Schein')
    public static void repairEmail(List<ID> ids){
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'casereply@affordablecare.com'];
        List<EmailTemplate> etemplate = [Select Id from EmailTemplate where name = 'Email to Henry Schein'];
        List<Case> cases = [Select Id, Contact.Id, SuppliedEmail from Case where Id in :ids];
        List<String> toAddr; 
        List<String> ccAddr; 
        Messaging.SingleEmailMessage mail;
        List<Messaging.SingleEmailMessage> allmsg= new List<Messaging.SingleEmailMessage>();          
        List<String> email_addr = new List<String>();
        
        for(Case c: cases){
            if (c.contact.Id == null){
                email_addr.add(c.SuppliedEmail);     
            }                
        }
        List<Contact> contact = [Select Id, email from contact where email in :email_addr];
        
               
        for(Case c: cases) {            
            mail = new Messaging.SingleEmailMessage();
            toAddr = new List<String>();
            ccAddr = new List<String>();
            toAddr.add('NDSOHelpDesk@henryschein.com');   
            ccAddr.add('douglas.vann@affordablecare.com');
            mail.optoutpolicy='FILTER';
            mail.setUseSignature(false);
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            mail.setBCCSender(false);
            mail.toaddresses = toaddr;
            mail.ccaddresses = ccAddr;
            mail.setWhatId(c.id);
            
            if(c.Contact.Id != null)
                mail.setTargetObjectId(c.Contact.Id);   
            else{
                for(Contact con: contact){
                    if(c.SuppliedEmail == con.email){
                        mail.setTargetObjectId(con.Id);
                        break;
                    }                        
                }
            }
            mail.setTreatTargetObjectAsRecipient(false);
            
            if ( etemplate.size() > 0 ) {
                mail.setTemplateId(etemplate.get(0).Id);
            }  
            allmsg.add(mail);               
        }
        

        Messaging.sendEmail(allmsg,false);

    }

}