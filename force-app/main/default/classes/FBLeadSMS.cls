public class FBLeadSMS {
    
    public static Set<Id> contactIds = new Set<Id>();
    public static Map<Id,String> contactMobileNos = new Map<Id,String>();
    public static Map<Id,String> contactTimeZone = new Map<Id,String>();
    
    public static void sendFBLeadSMS(List<FB_Lead__c> lstFBleads){
        
        if(lstFBleads.size() > 0){        
            Set<Id> practiceId = new Set<Id>();
            Map<Id,Account> mapAccCon = new Map<Id,Account>();		
            List<TwilioSF__Message__c> msg = new List<TwilioSF__Message__c>();
            String fromNumber = '+18332851921';             
            Id Contact1, Contact2;
            List<String> lstToNumber = new List<String>();
            String body = '';
            
            practiceId = setPracticeIdFromLeads(lstFBleads,practiceId);
            mapAccCon = setContactMapFromPractice(practiceId,mapAccCon);
            getContactNumAndTimeZone(contactIds);
            
            for(FB_Lead__c lead: lstFBLeads){
                if(lead.Lead__c != null) {
                     body = 'ADI Marketing Team: Facebook Messenger Lead Alert - New Lead Received';
                }
                else {
                     body = 'ADI Marketing Team: Facebook Lead Alert - New Lead Received';
                }

            	Contact1 = mapAccCon.get(lead.FB_Practice__c).FB_SMS_Contact1__c; 
                Contact2 = mapAccCon.get(lead.FB_Practice__c).FB_SMS_Contact2__c;
               	lstToNumber = getSMSNumbers(Contact1,lstToNumber);
               	lstToNumber = getSMSNumbers(Contact2,lstToNumber);
            }
            
             for(String toNumber: lstToNumber)
                msg = createTwilioMsg(msg,toNumber,fromNumber,body); 
           
            insertTwilioMsg(msg);
            updateFBLeadSMSTimeStamp(lstFBleads, mapAccCon);     
           
        }
    }

    public static Set<Id> setPracticeIdFromLeads(List<FB_Lead__c> lstFBleads, Set<Id> practiceId){       
        for(FB_Lead__c lead: lstFBleads){           
            practiceId.add(lead.FB_Practice__c);        
        }
        return practiceId;
    }
    
    public static Map<Id,Account> setContactMapFromPractice(Set<Id> practiceId, Map<Id,Account> mapAccCon){
        
        if(practiceId.size() > 0){
            for(Account acc: [Select Id, FB_SMS_Contact1__c, FB_SMS_Contact2__c From Account where Id in :practiceId]){
            	mapAccCon.put(acc.Id,acc);  
                if(acc.FB_SMS_Contact1__c != NULL)
                	contactIds.add(acc.FB_SMS_Contact1__c);
                if(acc.FB_SMS_Contact2__c != NULL)
                	contactIds.add(acc.FB_SMS_Contact2__c);
            }
        }                    
        return mapAccCon;
    }
    
    public static void getContactNumAndTimeZone(Set<Id> contactIds){
        if(contactIds.size() > 0){
            List<Contact> lstCon = [Select Id, MobilePhone, Account.Local_Time_24_Short__c From Contact where id in :contactIds];       
            For(Contact c: lstCon){
                contactMobileNos.put(c.Id,c.MobilePhone);            
                contactTimeZone.put(c.Id,c.Account.Local_Time_24_Short__c);
            }
        }
    }
    
    public static List<String> getSMSNumbers(Id ContactId, List<String> lstToNumber){
        if(ContactId != NULL){
            if(contactMobileNos.get(ContactId) != Null && contactMobileNos.get(ContactId) != ''){
                if(isValidContactTime(ContactId))
                    lstToNumber.add(String.valueOf('+1' + contactMobileNos.get(ContactId)));
            }
        }        
        return lstToNumber;
    }

    public static Boolean isValidContactTime(Id ContactId){
        if(contactTimeZone.get(ContactId) != NULL && contactTimeZone.get(ContactId) != ''){
            String[] strTime = contactTimeZone.get(ContactId).split(' ');
            String[] localTime = strTime[0].split(':');
            Time localTimeStamp = Time.newInstance(Integer.valueOf(localTime[0]),Integer.valueOf(localTime[1]),0,0);
            Time timeStampRange1 = Time.newInstance(7, 0, 0, 0);
            Time timeStampRange2 = Time.newInstance(20, 0,0 , 0);
            if(localTimeStamp < timeStampRange1 || localTimeStamp > timeStampRange2)
                return false;
            else
                return true;
        }
        return false;
    }
    
    public static List<TwilioSF__Message__c> createTwilioMsg(List<TwilioSF__Message__c> msg, String toNumber, 
                                                             String fromNumber, String body){
        if(toNumber != null && toNumber != ''){            
            TwilioSF__Message__c tmsg = new TwilioSF__Message__c();
            tmsg.TwilioSF__From_Number__c = fromNumber;
            tmsg.TwilioSF__To_Number__c = toNumber;
            tmsg.TwilioSF__Body__c = body;
            tmsg.TwilioSF__Direction__c = 'outbound-api';
            msg.add(tmsg);
        }
        return (msg);
    }
    
    public static void insertTwilioMsg(List<TwilioSF__Message__c> msg){
        
        try{
            insert msg;
        }
        catch(Exception e){
            System.debug('Error while inserting Twilio msg via FB lead: ' + e.getMessage());
        }
    }
    public static void updateFBLeadSMSTimeStamp(List<FB_Lead__c> lstFBleads, Map<Id,Account> mapAcc){
        for(FB_Lead__c lead: lstFBleads){
            if(mapAcc.size() > 0 && mapAcc.get(lead.FB_Practice__c) != null){
                Id ContactId = mapAcc.get(lead.FB_Practice__c).FB_SMS_Contact1__c;
                if(contactMobileNos.get(ContactId) != Null && contactMobileNos.get(ContactId) != ''
                  && isValidContactTime(ContactId)){                   
                       lead.SMS1_Notification_Sent_Date__c = DateTime.now();      
                }

				ContactId = mapAcc.get(lead.FB_Practice__c).FB_SMS_Contact2__c;                
                if(contactMobileNos.get(ContactId) != Null && contactMobileNos.get(ContactId) != ''
                  && isValidContactTime(ContactId)){                  
                       lead.SMS2_Notification_Sent_Date__c = DateTime.now();                  
                }
        }            
           
        }
        try{
            update lstFBleads;
        }
        catch(Exception e){
            System.debug('Error while updating FB lead SMS timestamp: ' + e.getMessage());
        }
    }     
}