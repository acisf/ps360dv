global class FixFBLeadPracticeBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, FB_Practice_Id__c, FB_Practice__c, FB_Zip__c, FB_Ad_Name__c  //need to restrict what I'm updating
            FROM FB_Lead__c
            WHERE CreatedDate = THIS_YEAR
        ]);
    }

    global void execute(Database.BatchableContext bc, List<FB_Lead__c> scope) {

        Set<String> locationIds = new Set<String>();
        Set<String> zipCodes = new Set<String>();

        // First pass: collect location IDs + ZIPs
        for (FB_Lead__c l : scope) {
            String locFromAd = AutoFBLeads.getLocationId(l.FB_Ad_Name__c);
            if (locFromAd != '00000') {
                locationIds.add(locFromAd);
            }
            if (String.isNotBlank(l.FB_Zip__c)) {
                zipCodes.add(l.FB_Zip__c);
            }
        }

        // Lookup practices
        Map<String, Account> practiceMap = new Map<String, Account>();
        if (!locationIds.isEmpty()) {
            for (Account a : [
                SELECT Id, Location_ID_5_digit__c
                FROM Account
                WHERE Location_ID_5_digit__c IN :locationIds
            ]) {
                practiceMap.put(a.Location_ID_5_digit__c, a);
            }
        }

        // Lookup ZIP → closest practice
        Map<String, Zip_Code__c> zipMap = new Map<String, Zip_Code__c>();
        if (!zipCodes.isEmpty()) {
            for (Zip_Code__c z : [
                SELECT Zip__c,
                       Practice_1__c, Practice_1_Location_Id__c, Practice_1_brand__c,
                       Practice_2__c, Practice_2_Location_Id__c, Practice_2_brand__c,
                       Practice_3__c, Practice_3_Location_Id__c, Practice_3_brand__c
                FROM Zip_Code__c
                WHERE Zip__c IN :zipCodes
            ]) {
                zipMap.put(z.Zip__c, z);
            }
        }

        List<FB_Lead__c> updates = new List<FB_Lead__c>();

        for (FB_Lead__c l : scope) {

            String adLoc = AutoFBLeads.getLocationId(l.FB_Ad_Name__c);
            Boolean changed = false;

            // Priority 1: Ad Name
            if (adLoc != '00000' && practiceMap.containsKey(adLoc)) {
                Id newPracticeId = practiceMap.get(adLoc).Id;

                if (l.FB_Practice_Id__c != adLoc || l.FB_Practice__c != newPracticeId) {
                    l.FB_Practice_Id__c = adLoc;
                    l.FB_Practice__c = newPracticeId;
                    changed = true;
                }
            }
            // Priority 2: ZIP fallback
            else if (String.isNotBlank(l.FB_Zip__c) && zipMap.containsKey(l.FB_Zip__c)) {

                Zip_Code__c z = zipMap.get(l.FB_Zip__c);

                if (z.Practice_1_brand__c != null && z.Practice_1_brand__c.startsWith('Affordable Dentures')) {
                    l.FB_Practice__c = z.Practice_1__c;
                    l.FB_Practice_Id__c = z.Practice_1_Location_Id__c;
                    changed = true;
                } 
                else if (z.Practice_2_brand__c != null && z.Practice_2_brand__c.startsWith('Affordable Dentures')) {
                    l.FB_Practice__c = z.Practice_2__c;
                    l.FB_Practice_Id__c = z.Practice_2_Location_Id__c;
                    changed = true;
                } 
                else if (z.Practice_3_brand__c != null && z.Practice_3_brand__c.startsWith('Affordable Dentures')) {
                    l.FB_Practice__c = z.Practice_3__c;
                    l.FB_Practice_Id__c = z.Practice_3_Location_Id__c;
                    changed = true;
                }
            }

            if (changed) {
                updates.add(l);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('FixFBLeadPracticeBatch finished.');
    }
}