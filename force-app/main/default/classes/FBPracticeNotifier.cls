public class FBPracticeNotifier {
    
    public static void sendSMSNotifications() {
          List<FB_Lead__c> lstSMS = new List<FB_Lead__c>();
          List<FB_Lead__c> lstFBMessenger = [SELECT id,FB_Contact__c,FB_Practice__c, FB_Practice__r.FB_Lead_Optin__c, FB_Practice__r.FDA_Email__c,
                                  FB_Practice__r.FB_Practice_Email__c, FB_Practice__r.FB_Practice_CC_Email__c, FB_Practice__r.Time_Local__c, FB_Practice__r.Location_Id_5_Digit__c,
                                  FB_First_Name__c, FB_Last_Name__c, FB_Email__c, FB_Phone__c, FB_Campaign_Name__c, CreatedDate,
                                  FB_Practice__r.Notify_Practice_Exclusions__c, FB_Dental_Condition__c, FB_Current_Treatments__c,
                                  FB_Most_Important_Factor__c,  FB_Other_Dentists__c, FB_Interested_In_Financing__c,
                                  FB_Form__r.Name, FB_Notification_Sent_Date__c,SMS1_Notification_Sent_Date__c,SMS2_Notification_Sent_Date__c,
                                  ArchieBot_Total_Score__c, Lead__r.Name, Lead__r.Email, Lead__r.Phone, Lead__r.PostalCode,Lead__r.fB_Practice__c,
                                  Lead__r.Adibot_Preventing_Seeking_Treatment__c,Lead__r.Adibot_Type_Dental_Treatment__c,Lead__r.Adibot_Have_Dental_Insurance__c,
                                  Lead__r.Adibot_What_Dental_Insurance__c,Lead__r.Adibot_Interested_Financing_Options__c,Lead__r.Adibot_How_Soon_Tooth_Replacement__c ,
                                  Lead__r.ArchieBot_Extractions_NDWP__c,                                             
                                  FB_Zip__c,FB_How_Quickly__c,FB_Insurance_Provider__c,FB_Using_Insurance__c,FB_What_Service__c
                                  FROM  FB_Lead__c
                                  WHERE Lead__c != null
                                  AND FB_Practice__r.FB_Lead_Optin__c =: TRUE
                                  AND FB_Practice__r.FB_Notify_practice__c =: TRUE 
                                  AND FB_Practice__r.Facebook_SMS1__c != NULL                                      
                                  AND SMS1_Notification_Sent_Date__c = NULL 
                                  AND ArchieBot_Total_Score__c > 5
                                  AND CreatedDate = Last_N_Days: 3
                                  AND Lead__c IN (SELECT LeadId FROM MessagingSession WHERE Status = 'Ended' AND LeadId != null AND MessagingChannel.DeveloperName LIKE 'FACEBOOK%')
                                  LIMIT 5000]; 
        
        List<FB_Lead__c> lstFBForms =  [SELECT id,FB_Contact__c,FB_Practice__c, FB_Practice__r.FB_Lead_Optin__c, FB_Practice__r.FDA_Email__c,
                                  FB_Practice__r.FB_Practice_Email__c, FB_Practice__r.FB_Practice_CC_Email__c, FB_Practice__r.Time_Local__c, FB_Practice__r.Location_Id_5_Digit__c,
                                  FB_First_Name__c, FB_Last_Name__c, FB_Email__c, FB_Phone__c, FB_Campaign_Name__c, CreatedDate,
                                  FB_Practice__r.Notify_Practice_Exclusions__c, FB_Dental_Condition__c, FB_Current_Treatments__c,
                                  FB_Most_Important_Factor__c,  FB_Other_Dentists__c, FB_Interested_In_Financing__c,
                                  FB_Form__r.Name, FB_Notification_Sent_Date__c,SMS1_Notification_Sent_Date__c,SMS2_Notification_Sent_Date__c,
                                  ArchieBot_Total_Score__c, Lead__r.Name, Lead__r.Email, Lead__r.Phone, Lead__r.PostalCode,Lead__r.fB_Practice__c,
                                  Lead__r.Adibot_Preventing_Seeking_Treatment__c,Lead__r.Adibot_Type_Dental_Treatment__c,Lead__r.Adibot_Have_Dental_Insurance__c,
                                  Lead__r.Adibot_What_Dental_Insurance__c,Lead__r.Adibot_Interested_Financing_Options__c,Lead__r.Adibot_How_Soon_Tooth_Replacement__c ,
                                  Lead__r.ArchieBot_Extractions_NDWP__c,                                        
                                  FB_Zip__c,FB_How_Quickly__c,FB_Insurance_Provider__c,FB_Using_Insurance__c,FB_What_Service__c
                                  FROM  FB_Lead__c
                                  WHERE FB_Form__c !=NULL
                                  AND FB_Practice__r.FB_Lead_Optin__c =: TRUE 
                                  AND FB_Practice__r.FB_Notify_practice__c =: TRUE 
                                  AND FB_Practice__r.Facebook_SMS1__c != NULL                                      
                                  AND SMS1_Notification_Sent_Date__c = NULL 
                                  AND FB_CreatedTime__c = Last_N_Days: 3
                                  LIMIT 5000];
        
        lstSMS.addAll(lstFBMessenger);
        lstSMS.addAll(lstFBForms);
        FBLeadSMS.sendFBLeadSMS(lstSMS);
    }
    public static void sendFBFormLeadsNotification() {
        
        List<FB_Lead__c> lstFB = [SELECT id,FB_Contact__c,FB_Practice__c, FB_Practice__r.FB_Lead_Optin__c, FB_Practice__r.FDA_Email__c,
                                  FB_Practice__r.FB_Practice_Email__c, FB_Practice__r.FB_Practice_CC_Email__c, FB_Practice__r.Time_Local__c, 
                                  FB_Practice__r.Location_Id_5_Digit__c,
                                  FB_First_Name__c, FB_Last_Name__c, FB_Email__c, FB_Phone__c, FB_Campaign_Name__c, CreatedDate,
                                  FB_Practice__r.Notify_Practice_Exclusions__c,  FB_Dental_Condition__c, FB_Current_Treatments__c,
                                  FB_Most_Important_Factor__c,  FB_Other_Dentists__c, FB_Interested_In_Financing__c,
                                  FB_Form__r.Name, FB_Notification_Sent_Date__c,SMS1_Notification_Sent_Date__c,SMS2_Notification_Sent_Date__c,
                                  ArchieBot_Total_Score__c, Lead__r.Name, Lead__r.Email, Lead__r.Phone, Lead__r.PostalCode,Lead__r.fB_Practice__c,
                                  Lead__r.Adibot_Preventing_Seeking_Treatment__c,Lead__r.Adibot_Type_Dental_Treatment__c,Lead__r.Adibot_Have_Dental_Insurance__c,
                                  Lead__r.Adibot_What_Dental_Insurance__c,Lead__r.Adibot_Interested_Financing_Options__c,Lead__r.Adibot_How_Soon_Tooth_Replacement__c,
                                   Lead__r.ArchieBot_Extractions_NDWP__c,
                                  FB_Zip__c,FB_How_Quickly__c,FB_Insurance_Provider__c,FB_Using_Insurance__c,FB_What_Service__c
                                  FROM  FB_Lead__c
                                  WHERE FB_Form__c !=NULL
                                  AND FB_Notification_Sent_Date__c = NULL 
                                  AND FB_Practice__r.FB_Lead_Optin__c =: TRUE 
                                  AND FB_Practice__r.FB_Notify_practice__c =: TRUE 
                                  AND FB_CreatedTime__c = Last_N_Days: 3
                                  LIMIT 5000];
         System.debug(lstFB);
        FBLeadEmail.sendFBLeadNotification(lstFB,'Form');
        
    }
    
    public static void sendFBMessengerLeadsNotification() {
        
        List<FB_Lead__c> lstFB = [SELECT id,FB_Contact__c,FB_Practice__c, FB_Practice__r.FB_Lead_Optin__c, FB_Practice__r.FDA_Email__c,
                                  FB_Practice__r.FB_Practice_Email__c, FB_Practice__r.FB_Practice_CC_Email__c, FB_Practice__r.Time_Local__c,FB_Practice__r.Location_Id_5_Digit__c,
                                  FB_First_Name__c, FB_Last_Name__c, FB_Email__c, FB_Phone__c, FB_Campaign_Name__c, CreatedDate,
                                  FB_Practice__r.Notify_Practice_Exclusions__c, FB_Dental_Condition__c, FB_Current_Treatments__c,
                                  FB_Most_Important_Factor__c,  FB_Other_Dentists__c, FB_Interested_In_Financing__c,
                                  FB_Form__r.Name, FB_Notification_Sent_Date__c,SMS1_Notification_Sent_Date__c,SMS2_Notification_Sent_Date__c,
                                  ArchieBot_Total_Score__c, Lead__r.Name, Lead__r.Email, Lead__r.Phone, Lead__r.PostalCode,Lead__r.fB_Practice__c,
                                  Lead__r.Adibot_Preventing_Seeking_Treatment__c,Lead__r.Adibot_Type_Dental_Treatment__c,Lead__r.Adibot_Have_Dental_Insurance__c,
                                  Lead__r.Adibot_What_Dental_Insurance__c,Lead__r.Adibot_Interested_Financing_Options__c,Lead__r.Adibot_How_Soon_Tooth_Replacement__c ,
                                  Lead__r.ArchieBot_Extractions_NDWP__c,
                                  FB_Zip__c,FB_How_Quickly__c,FB_Insurance_Provider__c,FB_Using_Insurance__c,FB_What_Service__c
                                  FROM  FB_Lead__c
                                  WHERE Lead__c != null
                                  AND ArchieBot_Total_Score__c > 5
                                  AND FB_Notification_Sent_Date__c = NULL 
                                  AND FB_Practice__r.FB_Lead_Optin__c =: TRUE
                                  AND FB_Practice__r.FB_Notify_practice__c =: TRUE 
                                  AND CreatedDate = Last_N_Days: 3
                                  AND Lead__c IN (SELECT LeadId FROM MessagingSession WHERE Status = 'Ended' AND LeadId != null AND MessagingChannel.DeveloperName LIKE 'FACEBOOK%')
                                  LIMIT 5000]; 
        
        System.debug('List in FBPracticeNotifier.sendFBMessengerLeadsNotification: ' + lstFB);
        FBLeadEmail.sendFBLeadNotification(lstFB,'Messenger');
    }
    
    
}