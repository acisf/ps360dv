global class TxtReplyHandler implements Messaging.InboundEmailHandler { 
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env) {
        
        // Create an InboundEmailResult 
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        // Extract plain text and HTML body from the email
        String strPlainText = email.plainTextBody;
        String strHTML = email.htmlBody.stripHtmlTags(); // Remove HTML tags
        
        // Parse the email body to extract information
        Map<String, String> emailInfo = parseEmailBody(strHTML);
        
        // Lookup Account and Contact based on parsed information
        Account acc = findAccountByEmailInfo(emailInfo);
        List<Contact> contacts = findContactByEmailInfo(emailInfo,acc);
        
        // Create Contact if not found
        Contact con = null;
        if (contacts.isEmpty()) {
            con = createContact(emailInfo, acc);
        } else {
            con = contacts[0]; // Take the first contact if multiple found
        }
        
        // Create a Case record
        Case c = new Case();
        c.status = 'New';
        c.Origin = 'Email';
        c.subject = email.subject;
        c.Description = strHTML;
        c.RecordTypeId = getCallBackRecordTypeId(); // Set Record Type Id
        
        // Associate Case with Account if found
        if (acc != null) {
            c.AccountId = acc.Id;
        }
        
        // Associate Case with Contact if found or created
        if (con != null) {
            c.ContactId = con.Id;
        }
        
        // Insert Case record
        try {
            insert c;
        } catch(Exception e) {
            system.debug(e.getMessage());
             sendErrorEmail(e.getMessage(), emailInfo.get('OriginalEmailBody'));
        }
        
        // Return the result for the Apex Email Service
        result.success = true;
        return result;
    }
    
    // Method to parse email body and extract information
    private Map<String, String> parseEmailBody(String body) {
        Map<String, String> emailInfo = new Map<String, String>();
        emailInfo.put('OriginalEmailBody',body);
        // Split the email body by line breaks to extract key-value pairs
        List<String> lines = body.split('\n');
        
        // Iterate through each line to extract key-value pairs
        for (String line : lines) {
            if(line.contains('::')) {
                List<String> keyValue = line.trim().split('::');
                if (keyValue.size() == 2) {
                    emailInfo.put(keyValue[0].trim(), keyValue[1].trim());
                }
            }
        }
        
        return emailInfo;
    }
    
    // Method to find Account based on parsed email information
    private Account findAccountByEmailInfo(Map<String, String> emailInfo) {
        List<Account> lstA;
        if (emailInfo.containsKey('LocationId')) {
            String locationId = emailInfo.get('LocationId');
            locationId = locationId.leftPad(5, '0');
            
            lstA = [SELECT Id FROM Account WHERE Location_Id__c = :locationId LIMIT 1];
            if(lstA.size() > 0)
                return lstA[0];
        }
        return null;
    }
    
    // Method to find Contact based on parsed email information
    private List<Contact> findContactByEmailInfo(Map<String, String> emailInfo, Account a) {
        List<Contact> contacts = new List<Contact>();
        if (emailInfo.containsKey('FirstName') && emailInfo.containsKey('LastName') && emailInfo.containsKey('PhoneNumber')) {
            String firstName = emailInfo.get('FirstName');
            String lastName = emailInfo.get('LastName');
            String phoneNumber = emailInfo.get('PhoneNumber').replaceAll('[^0-9]', '');
            if (phoneNumber.length() > 10) {
                phoneNumber = phoneNumber.substring(phoneNumber.length() - 10); // Keep only the last 10 digits
            }
            contacts = [SELECT Id FROM Contact WHERE AccountId =: a.id AND FirstName = :firstName AND LastName = :lastName AND (NVM_MobilePhone__c = :phoneNumber OR NVM_HomePhone__c = :phoneNumber) LIMIT 1];
        }
        else if (emailInfo.containsKey('LastName') && emailInfo.containsKey('Email')) {
            String lastName = emailInfo.get('LastName');
            String email = emailInfo.get('Email');           
            if (contacts.isEmpty() && email != null) {
                contacts = [SELECT Id FROM Contact WHERE AccountId =: a.id AND LastName = :lastName AND Email = :email LIMIT 1];
                
            }
        }
        return contacts;
    }
    
    
    private Contact createContact(Map<String, String> emailInfo, Account acc) {
        Contact newContact = new Contact();
        newContact.FirstName = emailInfo.get('FirstName');
        newContact.LastName = emailInfo.get('LastName');
        newContact.Email = emailInfo.get('Email');
        
        String phoneNumber = emailInfo.get('PhoneNumber').replaceAll('[^0-9]', '');
        if (phoneNumber.length() > 10) {
            phoneNumber = phoneNumber.substring(phoneNumber.length() - 10); // Keep only the last 10 digits
        }
        newContact.MobilePhone = phoneNumber;
        
        if(acc != null)
            newContact.AccountId = acc.id;
        
        try {
            insert newContact;
        } catch(Exception e) {
            system.debug(e.getMessage()); 
            sendErrorEmail(e.getMessage(), emailInfo.get('OriginalEmailBody'));
            return null; 
        }
        
        return newContact;
    }
    
    // Method to send email in case of error inserting Case
    public void sendErrorEmail(String errorMessage, String originalEmailBody) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'douglas.vann@affordablecare.com'}; // Replace with your email address
            mail.setToAddresses(toAddresses);
        mail.setSubject('Error Inserting App-reminder-RES Case');
        mail.setPlainTextBody('Error Message: ' + errorMessage + '\nOriginal Email Body: ' + originalEmailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    // Method to get the Record Type Id for Case
    private Id getCallBackRecordTypeId() {
        return Schema.SObjectType.Case.getRecordTypeInfosByName().get('Call Back').getRecordTypeId();
    }
}