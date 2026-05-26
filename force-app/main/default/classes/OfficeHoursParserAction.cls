public with sharing class OfficeHoursParserAction {
    
    @InvocableMethod(label='Update Office Hours')
    public static void updateHours(List<Request> requests) {

        // Collect all Account IDs to query in bulk
        Set<Id> accountIds = new Set<Id>();
        for (Request req : requests) {
            if (req.recordId != null) accountIds.add(req.recordId);
        }

        // Query all Accounts at once
        Map<Id, Account> accountsMap = new Map<Id, Account>(
            [SELECT Id,
                    Mon_Open__c, Mon_Close__c,
                    Tues_Open__c, Tues_Close__c,
                    Wed_Open__c, Wed_Close__c,
                    Thurs_Open__c, Thurs_Close__c,
                    Fri_Open__c, Fri_Close__c,
                    Sat_Open__c, Sat_Close__c,
                    Office_Hours_Note__c
             FROM Account
             WHERE Id IN :accountIds]
        );

        for (Request req : requests) {
            Account acc = accountsMap.get(req.recordId);
            if (acc == null) continue;

            try {

                // Clean JSON to avoid non-breaking space errors
                String cleanJson = req.outputJson.replace('\u00A0',' ').trim();
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);

                // Populate each day
                acc.Mon_Open__c = (String)parsed.get('Mon_Open');
                acc.Mon_Close__c = (String)parsed.get('Mon_Close');
                acc.Tues_Open__c = (String)parsed.get('Tue_Open');
                acc.Tues_Close__c = (String)parsed.get('Tue_Close');
                acc.Wed_Open__c = (String)parsed.get('Wed_Open');
                acc.Wed_Close__c = (String)parsed.get('Wed_Close');
                acc.Thurs_Open__c = (String)parsed.get('Thu_Open');
                acc.Thurs_Close__c = (String)parsed.get('Thu_Close');
                acc.Fri_Open__c = (String)parsed.get('Fri_Open');
                acc.Fri_Close__c = (String)parsed.get('Fri_Close');
                acc.Sat_Open__c = (String)parsed.get('Sat_Open');
                acc.Sat_Close__c = (String)parsed.get('Sat_Close');
                
                if (parsed.containsKey('Office_Hours_Note')) {
                    acc.Office_Hours_Note__c = (String)parsed.get('Office_Hours_Note');
                }

            } catch (Exception e) {
                System.debug('Failed to parse JSON for Account ' + req.recordId + ': ' + e.getMessage());
            }
        }
 
        update accountsMap.values();
    }

    public class Request {
        @InvocableVariable public Id recordId;
        @InvocableVariable public String outputJson;
    }
}