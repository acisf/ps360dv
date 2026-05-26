public with sharing class PracticeMessageController {
    
  
   @AuraEnabled(cacheable=true)
    public static List<Office_Closing__c> getOfficeClosings(String practiceId) {
        return [
            SELECT Id,
                   Name,
                   Account__c,
                   Start_Date__c,
                   End_Date__c,
            	   Note__c,
            	   Display_Text__c,
                   Active__c
            FROM Office_Closing__c
            WHERE Active__c = TRUE
            AND Account__c = :practiceId
            ORDER BY Start_Date__c ASC
        ];
    }    
    
     @AuraEnabled(cacheable=true)
    public static List<Account> getOfficeIsClosed(String practiceId) {
        return [
            SELECT Id,
            IsClosed__c
            FROM Account
            WHERE Id = :practiceId
        ];
    } 
    
    
    @AuraEnabled(cacheable=true)
    public static List<Practice_Message__c> getPracticeMessages(String practiceId, String mode) {
        List<Practice_Message__c> lstPM = new List<Practice_Message__c>();
        
        //TO DO: This mode will not be needed after getOfficeClosings is implemented
        if(mode == 'Closures Only') {
            System.debug('Getting closures only');
            lstPM = [
                SELECT ID, Name, Active_Practice_Message__c, Message__c, Detailed_Messages__c,
                Start_Date__c, End_Date__c, Type__c 
                FROM Practice_Message__c 
                WHERE Practice__c = :practiceId
                AND Type__c = 'Temporarily Closed'
                AND (
                    (Start_Date__c <= TODAY AND End_Date__c > TODAY) 
                    OR (Start_Date__c <= TODAY AND End_Date__C = NULL)
                )
            ];
        }
        else
        {
            System.debug('Getting all messages');
            lstPM = [
                SELECT ID, Name, Active_Practice_Message__c, Message__c, Detailed_Messages__c,
                Start_Date__c, End_Date__c, Type__c 
                FROM Practice_Message__c 
                WHERE Practice__c = :practiceId
                AND (
                    (Start_Date__c <= TODAY AND End_Date__c > TODAY) 
                    OR (Start_Date__c <= TODAY AND End_Date__C = NULL)
                )
                ORDER BY Start_Date__c
            ];
        }
        
        return lstPM;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Scheduling_Requirements__c> getSchedulingRequirements(String practiceId) {
        List<Scheduling_Requirements__c> lstSR = new List<Scheduling_Requirements__c>();
        lstSR = [
            SELECT ID,
            Name, 
            Scheduling_Requirement_Note__c,
            Scheduling_Requirement_Type__c
            FROM Scheduling_Requirements__c 
            WHERE Practice__c = : practiceId
            ORDER BY Scheduling_Requirement_Type__c ASC 
        ];
        return lstSR;
    }
    
    @AuraEnabled(cacheable=true) 
    public static List<Special_Promotions__c> getSpecialPromotions(String practiceId) {
        List<Special_Promotions__c> lstPromo = new List<Special_Promotions__c>();
        lstPromo = [SELECT ID, Name, Promo_Start__c,Promo_Ends__c,Promo_Details__c,Promotion_Detail_Notes__c
                    FROM Special_Promotions__c
                    WHERE Practice__c = : practiceId                             
                    AND ((Promo_Start__c <= TODAY AND Promo_Ends__c > TODAY) 
                         OR (Promo_Start__c <= TODAY AND Promo_Ends__c = NULL))
                    ORDER BY Promo_Ends__c ASC ];  
        return lstPromo;
    }
}