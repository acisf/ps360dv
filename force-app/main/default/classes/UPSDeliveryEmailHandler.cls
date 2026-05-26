global class UPSDeliveryEmailHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            // 1. Extract Tracking Number (Look for '1Z' followed by 16 alphanumeric characters)
            String trackingNumber = extractTrackingNumber(email.subject + ' ' + (email.plainTextBody != null ? email.plainTextBody : ''));
            
            if (String.isNotBlank(trackingNumber)) {
                // 2. Find the most recent Case matching this tracking number
                List<Case> targetCases = [SELECT Id, Subject, Shipping_Status__c FROM Case 
                                         WHERE Tracking_Number__c = :trackingNumber 
                                         ORDER BY CreatedDate DESC LIMIT 1];
                
                if (!targetCases.isEmpty()) {
                    Case c = targetCases[0];
                    
                    // 3. Update Case Fields based on email content
                    updateCaseDetails(c, email);
                    update c;
                    
                    // 4. Attach Email to Case for record keeping
                    createEmailMessage(c.Id, email);
                    
                } else {
                    // Handle 'Not Found': Log it so it can be manually reviewed
                    handleOrphanEmail(email, trackingNumber);
                }
            }
        } catch (Exception e) {
            System.debug('Error processing UPS Email: ' + e.getMessage());
            result.success = false;
        }

        return result;
    }

    private String extractTrackingNumber(String text) {
        // UPS Standard Tracking Pattern
        Pattern p = Pattern.compile('1Z[A-Z0-9]{16}');
        Matcher m = p.matcher(text);
        return m.find() ? m.group(0) : null;
    }

    private void updateCaseDetails(Case c, Messaging.InboundEmail email) {
        String subject = email.subject;
        
        // Determine status based on common UPS subject line keywords
        if (subject.contains('Delivery Notification')) {
            c.Shipping_Status__c = 'Delivered'; 
        } else if (subject.contains('Exception Notification')) {
            c.Shipping_Status__c = 'Exception';
        } else if ( subject.contains('Label Created')) {
            c.Shipping_Status__c = 'Label Created'; 
        } else if (subject.contains('Ship Notification')) {
            c.Shipping_Status__c = 'In Transit'; 
        }
    }

    private void createEmailMessage(Id caseId, Messaging.InboundEmail email) {
        EmailMessage msg = new EmailMessage();
        msg.ParentId = caseId;
        msg.Subject = email.subject;
        msg.FromAddress = email.fromAddress;
        msg.FromName = email.fromName;
        msg.ToAddress = String.join(email.toAddresses, '; ');
        msg.TextBody = email.plainTextBody;
        msg.HtmlBody = email.htmlBody;
        msg.Status = '0';
        insert msg;
    }


    private void handleOrphanEmail(Messaging.InboundEmail email, String trackingNo) {
        // Create a Task for manual intervention if no matching case exists
        Task t = new Task();
        t.Subject = '[ACTION REQUIRED] Unlinked UPS Update: ' + trackingNo;
        t.Description = 'An update was received for a tracking number not found in Salesforce: ' + trackingNo + '\n\nSubject: ' + email.subject;
        t.Priority = 'High';
        t.Status = 'Not Started';
        insert t;
    }
}