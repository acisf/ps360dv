public class FBEmailHandler implements Messaging.InboundEmailHandler {
    
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        // Initialize the result
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        // Extract the email body and parse the patient information
       
        String emailBody;
        
        if(email.htmlBody!=null) {
             emailBody = email.htmlBody.stripHTMLTags();
        } else {
             emailBody = email.plainTextBody;
        }

        
        // Parse the email body to extract fields
        Map<String, String> parsedData = parseEmailBody(emailBody);
        
        // Look up the Account using the Location field
        Id accountId;
        try {
        Account account = [SELECT Id FROM Account WHERE Location_id__c = :parsedData.get('location') LIMIT 1];
            accountId = account.id;
        }
        catch (Exception e) {
            
        }
        
        // Create the Contact_Key__c field (First+Last+Phone)
        String contactKey = parsedData.get('first name') + '-' + parsedData.get('last name') + '-' + parsedData.get('phone');
        
        // Check if the contact exists
        Contact contact;
        try {
            contact = [SELECT Id FROM Contact WHERE Contact_Key__c = :contactKey LIMIT 1];
        } catch (Exception e) {
            contact = new Contact(
                FirstName = parsedData.get('first name').capitalize(),
                LastName = parsedData.get('last name').capitalize(),
                MobilePhone = parsedData.get('phone'),
                Email = parsedData.get('email'),
                AccountId = accountId, 
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId()
            );
            insert contact;
        }
        
        // Retrieve the queue ID
        Group queue = [SELECT Id FROM Group WHERE Name = 'Facebook Queue' AND Type = 'Queue' LIMIT 1];
        
        // Create a Case
        Case newCase = new Case(
            Subject = email.subject,
            ContactId = contact.Id,
            AccountId = accountId,
            Description = emailBody,
            Status = 'New',
            Origin = 'Email',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Facebook Lead').getRecordTypeId(),
            OwnerId = queue.Id, 
            NVMConnect__NextContactTime__c = DateTime.now()
        );
        insert newCase;
        
        result.success = true;
        return result;
    }
    
    private Map<String, String> parseEmailBody(String emailBody) {
        Map<String, String> data = new Map<String, String>();
        List<String> lines = emailBody.split('\n');
        
        for (String line : lines) {
            if (line.contains('::')) {
                List<String> parts = line.split('::');
                if (parts.size() == 2) {
                    data.put(parts[0].trim().toLowerCase(), parts[1].trim().toLowerCase());
                }
            }
        }
        
        return data;
    }
}