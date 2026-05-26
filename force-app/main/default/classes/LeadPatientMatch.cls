public class LeadPatientMatch implements Database.Batchable<SObject>, Database.Stateful { 
    
    private DateTime createdStart;
    private DateTime createdEnd;
    private Id tfRecordTypeId;
    
    public LeadPatientMatch(Date dtCreated) {
        createdStart = DateTime.newInstance(dtCreated, Time.newInstance(0,0,0,0));
        createdEnd   = DateTime.newInstance(dtCreated.addDays(1), Time.newInstance(0,0,0,0));
        
        tfRecordTypeId = Schema.SObjectType.Lead
            .getRecordTypeInfosByName()
            .get('Treatment Finder')
            .getRecordTypeId();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, user_Id__c, email__c, last_name__c,
            phone_appointment__c, home_phone__c
            FROM Zeta_User__c
            WHERE CreatedDate >= :createdStart
            AND CreatedDate <= :createdEnd
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Zeta_User__c> scope) {
        
        Set<String> emails = new Set<String>();
        Set<String> userIds = new Set<String>();
        
        for (Zeta_User__c z : scope) {
            sanitizeZetaUser(z);
            
            if (z.user_Id__c != null) userIds.add(z.user_Id__c);
            if (String.isNotBlank(z.email__c)) emails.add(z.email__c);
        }
        
        if (userIds.isEmpty()) return;
        
        List<Zeta_Event__c> events = [
            SELECT user_id__c, event_type__c, apptdate__c, timestamp__c
            FROM Zeta_Event__c
            WHERE CreatedDate >= :createdStart
            AND CreatedDate <= :createdEnd
            AND user_id__c IN :userIds
            AND event_type__c IN ('new_appt','rescheduled_appt')
            ORDER BY timestamp__c ASC
        ];
        
        if (events.isEmpty()) return;
        
        Map<String, Date> userToFirstAppt = new Map<String, Date>();
        Map<String, Zeta_Event__c> userToLatestEvent = new Map<String, Zeta_Event__c>();
        
        for (Zeta_Event__c e : events) {
            if (String.isBlank(e.apptdate__c)) continue;
            
            Date apptDate;
            
            try {
                // Try ISO first
                apptDate = Date.valueOf(e.apptdate__c);
            } catch (Exception ex1) {
                try {
                    // Fallback to locale format
                    apptDate = Date.parse(e.apptdate__c);
                } catch (Exception ex2) {
                    System.debug('Invalid apptdate__c: ' + e.apptdate__c);
                    continue;
                }
            }
            
            // First (earliest)
            if (!userToFirstAppt.containsKey(e.user_id__c)) {
                userToFirstAppt.put(e.user_id__c, apptDate);
            }
            
            // Latest (last wins due to ORDER BY)
            userToLatestEvent.put(e.user_id__c, e);
        }
        
        if (userToFirstAppt.isEmpty()) return;
        
        List<Lead> leads = [
            SELECT Id, Email, Phone, LastName, First_Appt_Date__c
            FROM Lead
            WHERE RecordTypeId = :tfRecordTypeId
            AND (Email IN :emails OR (Phone != null AND LastName != null))
        ];
        
        Map<String, Lead> emailToLead = new Map<String, Lead>();
        Map<String, Lead> phoneLastToLead = new Map<String, Lead>();
        
        for (Lead l : leads) {
            sanitizeLead(l);
            
            if (String.isNotBlank(l.Email)) {
                emailToLead.put(l.Email, l);
            }
            
            if (String.isNotBlank(l.Phone) && String.isNotBlank(l.LastName)) {
                phoneLastToLead.put(l.Phone + '-' + l.LastName, l);
            }
        }
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Zeta_User__c z : scope) {
            if (!userToFirstAppt.containsKey(z.user_Id__c)) continue;
            
            Lead matched;
            
            if (String.isNotBlank(z.email__c) && emailToLead.containsKey(z.email__c)) {
                matched = emailToLead.get(z.email__c);
            } else {
                String phone = z.phone_appointment__c != null ? z.phone_appointment__c : z.home_phone__c;
                if (String.isNotBlank(phone) && String.isNotBlank(z.last_name__c)) {
                    String key = phone + '-' + z.last_name__c;
                    if (phoneLastToLead.containsKey(key)) {
                        matched = phoneLastToLead.get(key);
                    }
                }
            }
            
            if (matched != null && matched.First_Appt_Date__c == null) {
                matched.First_Appt_Date__c = userToFirstAppt.get(z.user_Id__c);
                leadsToUpdate.add(matched);
            }
        }
        
        if (!leadsToUpdate.isEmpty()) {
            Database.update(leadsToUpdate, false);
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
    
    private void sanitizeLead(Lead l) {
        if (l.Phone != null) {
            String p = l.Phone.replaceAll('[^0-9]', '');
            if (p.length() > 10) p = p.substring(p.length()-10);
            l.Phone = p;
        }
        if (l.LastName != null) l.LastName = l.LastName.trim().toLowerCase();
        if (l.Email != null) l.Email = l.Email.trim().toLowerCase();
    }
    
    private void sanitizeZetaUser(Zeta_User__c z) {
        if (z.phone_appointment__c != null) {
            String p = z.phone_appointment__c.replaceAll('[^0-9]', '');
            if (p.length() > 10) p = p.substring(p.length()-10);
            z.phone_appointment__c = p;
        }
        if (z.home_phone__c != null) {
            String p = z.home_phone__c.replaceAll('[^0-9]', '');
            if (p.length() > 10) p = p.substring(p.length()-10);
            z.home_phone__c = p;
        }
        if (z.last_name__c != null) z.last_name__c = z.last_name__c.trim().toLowerCase();
        if (z.email__c != null) z.email__c = z.email__c.trim().toLowerCase();
    }
}