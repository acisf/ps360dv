global class BatchFBLeadToZeta implements Database.Batchable<sObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query FB_Lead__c records created yesterday        
        Date yesterday = Date.today().addDays(-1);
        DateTime startOfDay = DateTime.newInstance(yesterday, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay = DateTime.newInstance(yesterday, Time.newInstance(23, 59, 59, 999));
        
        return Database.getQueryLocator([
            SELECT Id,
            FB_First_Name__c, 
            FB_Last_Name__c, 
            FB_Email__c, 
            FB_Phone__c,
            FB_Ad_Name__c,
            Practice_Id__c,
            FB_What_Service__c,
            FB_How_Quickly__c,
            FB_Using_Insurance__c,
            FB_Insurance_Provider__c,
            Lead__c,
            Lead__r.Adibot_How_Soon_Tooth_Replacement__c,
            Lead__r.Adibot_Preventing_Seeking_Treatment__c,
            Lead__r.Adibot_Interested_Financing_Options__c,
            Lead__r.Adibot_What_Dental_Insurance__c,
            Lead__r.Adibot_Type_Dental_Treatment__c,
            Lead__r.Adibot_Have_Dental_Insurance__c,
            Lead__r.ArchieBot_Extractions_NDWP__c,
            CreatedDate
            FROM FB_Lead__c
            WHERE CreatedDate >= :startOfDay AND CreatedDate <= :endOfDay
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<FB_Lead__c> scope) {
        List<FB_Lead_Zeta__c> zetaRecords = new List<FB_Lead_Zeta__c>();
        
        for (FB_Lead__c lead : scope) {
            FB_Lead_Zeta__c zeta = new FB_Lead_Zeta__c();
            zeta.FB_Lead_Id__c = lead.Id;
            zeta.FB_First_Name__c = lead.FB_First_Name__c;
            zeta.FB_Last_Name__c = lead.FB_Last_Name__c;
            zeta.FB_Email__c = lead.FB_Email__c;
            zeta.FB_Phone__c = lead.FB_Phone__c;
            zeta.FB_Ad_Name__c = lead.FB_Ad_Name__c;
            zeta.Practice_Id__c = lead.Practice_Id__c;
            
            
            //lead qualification fiels from archiebot
            if(lead.lead__c !=null) {
                zeta.Treatment_Start_Timeframe__c = lead.Lead__r != null ? lead.Lead__r.Adibot_How_Soon_Tooth_Replacement__c : null;
                zeta.Barrier_To_Dental_Care__c = lead.Lead__r != null ? lead.Lead__r.Adibot_Preventing_Seeking_Treatment__c : null;
                zeta.Interested_In_Financing__c = lead.Lead__r != null ? lead.Lead__r.Adibot_Interested_Financing_Options__c : null;
                zeta.Dental_Insurance_Provider__c = lead.Lead__r != null ? lead.Lead__r.Adibot_What_Dental_Insurance__c : null;
                zeta.Dental_Treatment_Type__c = lead.Lead__r != null ? lead.Lead__r.Adibot_Type_Dental_Treatment__c : null;
                zeta.Has_Dental_Insurance__c = lead.Lead__r != null ? lead.Lead__r.Adibot_Have_Dental_Insurance__c : null;
                zeta.Requires_Extractions_for_New_Dentures__c = lead.Lead__r != null ? lead.Lead__r.ArchieBot_Extractions_NDWP__c : null;
            } else {
                zeta.Dental_Treatment_Type__c = lead.FB_What_Service__c;
                zeta.Treatment_Start_Timeframe__c = lead.FB_How_Quickly__c;
                zeta.Has_Dental_Insurance__c = lead.FB_Using_Insurance__c;
                zeta.Dental_Insurance_Provider__c = lead.FB_Insurance_Provider__c;          
            }
            
            zeta.Created_DateTime__c = String.valueOf(lead.CreatedDate);            
            zetaRecords.add(zeta);
        }
        
        if (!zetaRecords.isEmpty()) {
            insert zetaRecords;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Optional: Send email or log success/failure
    }
}