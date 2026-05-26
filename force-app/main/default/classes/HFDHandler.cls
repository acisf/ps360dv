Global class HFDHandler implements Messaging.inboundEmailHandler{
    
    Global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env ) {
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        Database.SaveResult sr;
        String strBody, strLocation;
        Id contactId;
        Map<string,string> mapFields;
        Account a;
        Contact cnt;	
        Case c;
        
        strBody = getEmailBody(email);
        strLocation = getLocationFromSubject(email.subject);
        a = getPracticeFromLocation(strLocation);
        mapFields = getFieldsFromEmailBody(strBody);
        cnt = createContact(a,mapFields);
        contactId = getExistingContactId(cnt);  
        
        if(contactId == null) {
            sr = Database.insert(cnt,false); 
            if (sr.isSuccess()) {
                System.debug('Successfully inserted contact. Contact ID: ' + sr.getId());
            } 
            else {             
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Contact fields that affected this error: ' + err.getFields());
                }
            }
        }  
        else {
            System.debug('Successfully found contact. Contact ID: ' + contactId);
            cnt.Id = contactId;
            sr = Database.update(cnt,false);
        }     
        
        //create new case
        if(a!=null && a.RecordType.Name == 'Schedule Assist') {
            c=createCase(email.subject,strBody,a.Id, cnt);
            sr = Database.insert(c,false); 
            if (sr.isSuccess()) {
                System.debug('Successfully inserted case. Case ID: ' + sr.getId());
            } 
            else {            
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Case fields that affected this error: ' + err.getFields());
                }
            } 
            
        }
        else {
            System.debug('Did not insert case - not SA');
        }
        
        // Return the result for the Apex Email Service
        result.success = true;
        return result;
        
    }
    
    public String getEmailBody(Messaging.InboundEmail email) {
        String strPlainText, strHTML;
        strPlainText = email.plainTextBody;
        strHTML = email.htmlBody;
        
        if(String.isNotEmpty(strPlainText)) {
            return strPlainText;
        }
        
        if(String.isNotEmpty(strHTML)) {       
            strHTML = strHTML.stripHtmlTags();
            return strHTML;        
        }
        return '';
    }
    
    public String getLocationFromSubject(String subject) {                
        String strLocation = '';         
        if(String.isNotEmpty(subject)){
            Pattern pat = Pattern.compile('([0-9]+)');
            Matcher matcher = pat.matcher(subject);
            while (matcher.find()) {
                strLocation = subject.substring(matcher.start(),matcher.end());
            }      
            strLocation = strLocation.leftPad(5,'0');
        }       
        
        return strLocation;            
    }  
    
    public Account getPracticeFromLocation(String strLocation) {
        List<Account> lstA;
        Account acct = null;
        lstA = [SELECT Id, Name, Location_Id_5_digit__c, RecordType.Name
                FROM Account WHERE 
                Location_Id_5_digit__c =: strLocation LIMIT 1];
        for(Account a: lstA) {
            acct = a;
        } 
        return acct;
    }
    public Map<String,String> getFieldsFromEmailBody(String strBody) {
        Map<string,string> mapFieldMap = new Map<string,string>();
        List<String> rows = new List<String>();
        rows = strBody.split('\n');
        
        for(string row:rows) {
            if(row.contains('::')) {
                string[] arr = row.split('::');
                if(arr.size() == 2) {
                    string field = arr[0];
                    string value = arr[1];
                    mapFieldMap.put(field,value);
                }   
            }
        }	        
        
        return mapFieldMap;	
    }
    
    public Contact createContact(Account a, map<string,string> fields) {
        
        Contact c = new Contact();
        String strPhone;
        
        if(a != null)
            c.AccountId = a.Id;	
        
        c.HFD__c = true;        
        for(String field :fields.keySet()) {
            if(field == 'FirstName')  
                c.FirstName = fields.get('FirstName');
            if(field=='LastName') 
                c.LastName = fields.get('LastName');
            if(field == 'PhoneNumber')  {
                strPhone = fields.get('PhoneNumber');
                
                if(!String.isEmpty(strPhone)) {
                    strPhone = strPhone.replaceAll('[^0-9]', '');
                    if (strPhone.length() > 10) {
                        strPhone = strPhone.substring(strPhone.length() - 10); // Keep only the last 10 digits
                    }
                    c.MobilePhone = strPhone;
                }
            }
            
            if(field == 'Email')
                c.Email = fields.get('Email');
        } 
        
        if(!validateEmail(c.Email)) {
            c.Email = null;
        }
        
        if(String.isNotBlank(c.MobilePhone)) {
            c.MobilePhone = c.MobilePhone.replace('+','');
        }
        
        return c;
    }
    
    public Id getExistingContactId(Contact c) {
        
        If(c==null) 
            return null;
        
        List<Contact> lstContacts;
        Id cid= null;
        
        lstContacts = [SELECT Id FROM Contact WHERE AccountId =:c.AccountId AND
                       ((FirstName =: c.FirstName AND
                         LastName =: c.LastName AND
                         NVM_MobilePhone__c =: c.MobilePhone) OR
                        (FirstName =: c.FirstName AND
                         LastName =: c.LastName AND
                         Email =: c.Email) OR
                        (FirstName =: c.FirstName AND
                         LastName =: c.LastName AND
                         NVM_HomePhone__c =: c.MobilePhone))
                       LIMIT 1];	
        
        for(Contact cnt:lstContacts) {
            if(cid == null) 
                cid = cnt.Id;
        }
        
        return cid;
    }
    
    public Case createCase(String subject, String description, Id practiceId, Contact cnt) {        
        
        Case c = new Case();
        Id idHFD = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HFD').getRecordTypeId();
        AssignmentRule AR = new AssignmentRule();
        AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];	
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        dmlOpts.EmailHeader.TriggerUserEmail = false;
        dmlOpts.EmailHeader.triggerAutoResponseEmail = false;       
        
        if(String.isNotBlank(subject) && String.isNotBlank(description)) {
            c.status='New';
            c.Origin='Email';
            c.RecordTypeId = idHFD;
            c.subject = subject;
            c.Description = description;            
            c.setOptions(dmlOpts);
        }
        
        if(cnt != null && cnt.Id !=null) {
            c.AccountId = practiceId;
            c.ContactId = cnt.Id;
            c.SuppliedPhone = cnt.Phone;
            c.SuppliedName = cnt.FirstName + ' ' + cnt.LastName;
        }
        
        return c;
        
    }
    
    public Boolean validateEmail(String email) {
        Boolean res = true;
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: http://www.regular-expressions.info/email.html
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);
        if (!MyMatcher.matches()) 
            res = false;
        return res;	
    }
}