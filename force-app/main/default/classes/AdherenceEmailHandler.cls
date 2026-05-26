global class AdherenceEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail( Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        if (!hasAttachment(email)) {
            System.debug('No attachments found.');
            result.success = true;
            return result;
        }
        
        Messaging.InboundEmail.TextAttachment attachment = getFirstAttachment(email);
        
        if (!isCsvAttachment(attachment)) {
            System.debug('Attachment is not a CSV file.');
            result.success = true;
            return result;
        }
        
        List<String> lines = getLinesFromAttachment(attachment);
        List<Adherence__c> recordsToUpsert = new List<Adherence__c>();
        Set<String> agentDateIds = new Set<String>();
        Set<String> agentEmails = new Set<String>();
        
        for (Integer i = 1; i < lines.size(); i++) { // skip header
            Adherence__c record = processCsvRow(lines[i]);
            if (record != null) {
                recordsToUpsert.add(record);
                agentDateIds.add(record.AgentDateId__c);
                agentEmails.add(record.Calabrio_Person_Email__c);
            }
        }
        
        upsertAdherenceRecords(recordsToUpsert, agentEmails);
        deleteInvalidRecords(agentDateIds);
        sendReplyEmail(email.fromAddress,attachment.FileName, lines.size());
        
        
        result.success = true;
        
        return result;
    }
    
    // --- helper functions ---
    
    @TestVisible private static Boolean hasAttachment(Messaging.InboundEmail email) {
        return email.textAttachments != null && !email.textAttachments.isEmpty();
    }
    
    @TestVisible private static Messaging.InboundEmail.TextAttachment getFirstAttachment(Messaging.InboundEmail email) {
        return email.textAttachments[0];
    }
    
    @TestVisible private static Boolean isCsvAttachment(Messaging.InboundEmail.TextAttachment att) {
        return att.fileName != null && att.fileName.endsWithIgnoreCase('.csv');
    }
    
    @TestVisible private static List<String> getLinesFromAttachment(Messaging.InboundEmail.TextAttachment att) {
        String csvContent = att.body.toString();
        return csvContent.replace('\r\n', '\n').split('\n');
    }
    
    @TestVisible private static Adherence__c processCsvRow(String line) {
        String trimmed = line.trim();
        if (String.isBlank(trimmed)) return null;
        
        List<String> cols = parseCsvLine(trimmed);
        if (cols.size() < 7) return null;
        
        String agentEmail = cols[1].trim().toLowerCase();
        if (String.isBlank(agentEmail)) return null;
        
        Date shiftDate = parseDate(cols[2]);
        
        Adherence__c rec = new Adherence__c();
        rec.employeeIdentifier__c = agentEmail;
        rec.Calabrio_Person_Email__c = agentEmail;
        rec.Calabrio_Shift_Date__c = shiftDate;
        rec.adherenceStartDate__c = DateTime.newInstance(shiftDate, Time.newInstance(0, 0, 0, 0));
        rec.adherenceEndDate__c = DateTime.newInstance(shiftDate, Time.newInstance(0, 0, 0, 0));
        rec.Calabrio_In_Adherence_Time__c = tryParseDecimal(cols[4]);
        rec.Calabrio_Neutral_Adherence_Time__c = tryParseDecimal(cols[5]);
        rec.Calabrio_Out_of_Adherence_Time__c = tryParseDecimal(cols[6]);
        rec.AgentDateId__c = agentEmail + '_' + shiftDate.format();
        return rec;
    }
    
    @TestVisible private static void upsertAdherenceRecords(List<Adherence__c> records, Set<String> agentEmails) {
        if (records.isEmpty()) return;
        Map<String, Id> agentMap = new Map<String, Id>();
        for (User u : [SELECT Id, FederationIdentifier FROM User WHERE FederationIdentifier IN :agentEmails]) {
            agentMap.put(u.FederationIdentifier.toLowerCase(), u.Id);
        }
        for (Adherence__c rec : records) {
            rec.Agent__c = agentMap.get(rec.Calabrio_Person_Email__c);
        }
        upsert records AgentDateId__c;
    }
    
    @TestVisible private static void deleteInvalidRecords(Set<String> agentDateIds) {
        if (agentDateIds.isEmpty()) return;
        List<Adherence__c> toDelete = [
            SELECT Id FROM Adherence__c
            WHERE AgentDateId__c IN :agentDateIds
            AND ((Calabrio_In_Adherence_Time__c = 0 AND Calabrio_Out_of_Adherence_Time__c = 0)
                 OR  (Calabrio_In_Adherence_Time__c = null AND Calabrio_Out_of_Adherence_Time__c = NULL))
        ];
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
    
    // --- utility functions ---
    
    @TestVisible private static Date parseDate(String rawDateStr) {
        String dateOnly = rawDateStr.split(' ')[0];
        List<String> parts = dateOnly.split('/');
        if (parts.size() == 3) {
            return Date.newInstance(
                Integer.valueOf(parts[2]),
                Integer.valueOf(parts[0]),
                Integer.valueOf(parts[1])
            );
        }
        return null;
    }
    
    @TestVisible private static Decimal tryParseDecimal(String val) {
        try { return String.isBlank(val) ? null : Decimal.valueOf(val); }
        catch (Exception e) { return null; }
    }
    
    @TestVisible private static List<String> parseCsvLine(String line) {
        List<String> fields = new List<String>();
        Boolean inQuotes = false;
        String current = '';
        for (Integer i = 0; i < line.length(); i++) {
            String c = line.substring(i, i+1);
            if (c == '"') {
                if (inQuotes && i+1 < line.length() && line.substring(i+1, i+2) == '"') {
                    current += '"'; i++;
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (c == ',' && !inQuotes) {
                fields.add(current); current = '';
            } else {
                current += c;
            }
        }
        fields.add(current);
        return fields;
    }
    
    @TestVisible
    private static void sendReplyEmail(String toAddress, String fileName, Integer rowNum) {
        if (String.isBlank(toAddress)) return;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { toAddress });
        mail.setSubject('Adherence Upload Results');
        mail.setPlainTextBody(
            'Your adherence file has been processed.' + '\n' +
            'File Name: ' + fileName + '\n' +
            'Rows: ' + rowNum + '\n\n' +
            'Thank you.'
        );
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}