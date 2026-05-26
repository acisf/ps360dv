public class FBLeadEmail {
    
    public static void sendFBLeadNotification( List<FB_Lead__c> lstFB, String strType) { 
        
        OrgWideEmailAddress[] owea;
        List<Messaging.SingleEmailMessage> allmsg= new List<Messaging.SingleEmailMessage>();    
        Messaging.SingleEmailMessage mail;    
        List<FB_Lead__c> lstNewFB = new List<FB_Lead__c>();         
        Set<Id> fbIds = new Set<Id>();	 
        List<String> toAddr;
        List<String> ccAddr;
        List<String> bccAddr;
        String strSubject = '';
        String strHTML = '';
        String[] strExclusions;	
        Integer intLoop = 0;         
        
        owea = [select Id from OrgWideEmailAddress where Address = 'patientsupport@affordablecare.com'];        
        
        System.debug('List in FBLeadEmail ' + lstFB);
        
        //check for any campaign exclusions
        for(FB_Lead__c fb: lstFB){            
            if(fb.FB_Practice__r.Notify_Practice_Exclusions__c != NULL && fb.FB_Practice__r.Notify_Practice_Exclusions__c != ''){
                strExclusions = fb.FB_Practice__r.Notify_Practice_Exclusions__c.split(',');
                for(intLoop = 0; intLoop < strExclusions.size(); intLoop++){
                    if(String.isNotEmpty(fb.FB_Campaign_Name__c)) {
                        if(fb.FB_Campaign_Name__c.contains(strExclusions[intLoop]) && strExclusions[intLoop].endswith('_')) {
                            fbIds.add(fb.id);
                            break;
                        }
                    }
                }
            }
            
            if(fbIds.add(fb.id))
                lstNewFB.add(fb);
        }
        
        System.debug('List in FBLeadEmail ' + lstNewFB);
        
        //loop leads and create mail
        for(FB_Lead__c fb:lstNewFB) {
            mail = new Messaging.SingleEmailMessage();
            toAddr = new List<String>(); 
            ccAddr = new List<String>();
            bccAddr = new List<String>();
            String strRating = ''; 
            
            if(strType == 'Messenger') {
                
                
                if(fb.ArchieBot_Total_Score__c > 13)  {
                    strRating = 'HOT';
                }                	
                else if(fb.ArchieBot_Total_Score__c > 5) {
                    strRating = 'WARM';
                }
                else {                    
                    strRating = 'COLD';
                }        
                
                strSubject = 'FB Messenger Lead: ' + fb.FB_First_Name__c + ' ' + fb.FB_Last_Name__c;
                strHTML = 'A potential new patient has submitted information to Archie, our Facebook Messenger chatbot:<br/><br/>'; 
            }
            else {
                strSubject = 'New Facebook Lead: ' + fb.FB_First_Name__c + ' ' + fb.FB_Last_Name__c + ' - ' +  fb.FB_Campaign_Name__c;
                strHTML = 'A potential new patient has submitted an information request form on Facebook:<br/><br/>'; 
            }  
            
            if(strRating == 'HOT') {                  
                strSubject = '*' + strRating + '* ' + strSubject;
                strHTML+= '<b>NEXT BEST ACTION: </b> Connect with this prospect as soon as possible*.<br/><br/>';
            } 
            else if (strRating == 'WARM') {  
                strSubject = '*' + strRating + '* ' + strSubject;
                strHTML+= '<b>NEXT BEST ACTION: </b> Connect with this prospect when you have the time.*<br/><br/>';
            }
            else {
                strHTML+= '<b>NEXT BEST ACTION: </b> Connect with this prospect when you have the time.<br/><br/>';
            }
            
            
            strHTML += '===================' + '<br/>';
            strHTML += 'Patient Information' + '<br/>';
            strHTML += '===================' + '<br/>';
            strHTML += 'First Name:: ' + fb.FB_First_Name__c + '<br/>' ;
            strHTML += 'Last Name:: ' + fb.FB_Last_Name__c + '<br/>';
            strHTML += 'Phone:: ' + fb.FB_Phone__c + '<br/>';
            strHTML += 'Email:: ' + fb.FB_Email__c + '<br/>';  
            
            if (String.isNotBlank(fb.FB_Zip__c)) {
                strHTML += 'Zip:: ' + fb.FB_Zip__c + '<br/>';
            }
            strHTML += 'Location:: ' + fb.FB_Practice__r.Location_Id_5_Digit__c + '<br/>';              
            strHTML += 'Created:: ' + fb.FB_Practice__r.Time_Local__c + '<br/>';
            
            Boolean hasExtra = 
                String.isNotBlank(fb.FB_How_Quickly__c) ||
                String.isNotBlank(fb.FB_Insurance_Provider__c) ||
                String.isNotBlank(fb.FB_Using_Insurance__c) ||
                String.isNotBlank(fb.FB_What_Service__c);
            
            if (hasExtra) {
                strHTML += '==============================' + '<br/>';
                strHTML += 'Lead Qualification Information' + '<br/>';
                strHTML += '==============================' + '<br/>';
                if (String.isNotBlank(fb.FB_What_Service__c)) {
                    strHTML += 'Interested In Service:: ' + cleanupValue(fb.FB_What_Service__c, false) + '<br/>';
                }
                if (String.isNotBlank(fb.FB_How_Quickly__c)) {
                    strHTML += 'How Soon They Would Like to Start Treatment:: ' + cleanupValue(fb.FB_How_Quickly__c, false) + '<br/>';
                }
                if (String.isNotBlank(fb.FB_Using_Insurance__c)) {
                    strHTML += 'Using Insurance:: ' + cleanupValue(fb.FB_Using_Insurance__c, false) + '<br/>';
                }
                if (String.isNotBlank(fb.FB_Insurance_Provider__c)) {
                    strHTML += 'Insurance Provider:: ' + cleanupValue(fb.FB_Insurance_Provider__c, true) + '<br/>';
                }
                strHTML += '<br/><br/>';
                
                
            }
            
            
            if(strType == 'Messenger' && strRating != '') {   
                strHTML += 'Lead Rating:: ' + strRating + br() + br();
                strHTML += insertMessengerDetails(fb);
            }             
            
            //to address is fb_practice_email__c, otherwise fda email
            if(fb.FB_Practice__r.FB_Practice_Email__c != NULL){
                toAddr = fb.FB_Practice__r.FB_Practice_Email__c.split(',');                 
            }     
            else {
                toAddr.add(fb.FB_Practice__r.FDA_Email__c);   
            }    
            
            if(fb.FB_Practice__r.FB_Practice_CC_Email__c != NULL){
                ccAddr = fb.FB_Practice__r.FB_Practice_CC_Email__c.split(',');   
            } 
            
            
            bccAddr.add('douglas.vann@affordablecare.com'); 
            
            if(strType == 'Messenger') {
                bccAddr.add('valerie.stover@affordablecare.com');
                ccAddr.add('fb_alert@ciqgptvizhwm88juchtzn79ds2v5kar394remxkl9jeko72hi.36-b2oveaa.usa582.apex.salesforce.com');
                
            }
            
            mail.setUseSignature(false);
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            
            mail.setSubject(strSubject);
            mail.setHtmlBody(strHTML);
            mail.setPlainTextBody(strHTML.stripHtmlTags());
            mail.setBCCSender(false); 
            mail.setToAddresses(toaddr); 
            mail.setCcAddresses(ccaddr);  
            mail.setBccAddresses(bccAddr);
            allmsg.add(mail);     
            fb.FB_Notification_Sent_Date__c = Date.today();   
            System.debug('Set FB Lead Notification Date: ' + fb.FB_Notification_Sent_Date__c);
        } 
        
        //send mail and timestamp
        Messaging.sendEmail(allmsg,false);
        update lstNewFb;      
    }
    
    private static String cleanupValue(String input, Boolean capitalizeAll) {
        if (String.isBlank(input)) return '';
        
        // Replace underscores with spaces
        String cleaned = input.replace('_', ' ');
        cleaned = cleaned.toLowerCase();
        
        List<String> words = cleaned.split(' ');
        for (Integer i = 0; i < words.size(); i++) {
            if (String.isNotBlank(words[i]) && (capitalizeAll || i == 0)) {
                words[i] = words[i].substring(0,1).toUpperCase() + words[i].substring(1);
            }
        }
        return String.join(words, ' ');
    }
    
    
    private static String insertMessengerDetails(FB_lead__c fbLead) {
        String strHTM = '';
        strHTM += '===============================' + br();
        strHTM += 'FACEBOOK MESSENGER TRANSCRIPT' + br();
        strHTM += '===============================' + br();
        strHTM += br() + '<b>Can I have your full name to make our chat more personal?</b>' + br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Name) ? fbLead.Lead__r.Name : '';
        strHTM += br() +'<b>Could you please provide your email? I’ll use it to send you all the important details from our chat.</b>'+br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Email) ? fbLead.Lead__r.Email : '';
        strHTM += br() +'<b>May I have your phone number? I will use it to have one of our team follow up with a text or call to further assist you once we finish our chat.</b>'+br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Phone) ? fbLead.Lead__r.Phone : '';
        strHTM += br() + '<b>To best serve you, could you enter your zip code? This helps me connect you with the nearest office.</b>' + br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.PostalCode) ? fbLead.Lead__r.PostalCode : '';
        strHTM += br() + '<b>Have any obstacles been in the way of seeking dental care?</b>' + br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Adibot_Preventing_Seeking_Treatment__c) ? fbLead.Lead__r.Adibot_Preventing_Seeking_Treatment__c : '';
        strHTM += br() + '<b>Which dental treatment are you thinking about?</b>'+br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Adibot_Type_Dental_Treatment__c) ? fbLead.Lead__r.Adibot_Type_Dental_Treatment__c : '';
        
        strHTM += br() + '<b>Would you require extractions as a first-time denture wearer?</b>'+br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.ArchieBot_Extractions_NDWP__c) ? fbLead.Lead__r.ArchieBot_Extractions_NDWP__c : '';
        
        strHTM += br() + '<b>Do you currently have dental insurance?</b>'+br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Adibot_Have_Dental_Insurance__c) ? fbLead.Lead__r.Adibot_Have_Dental_Insurance__c : '';
        strHTM += br() + '<b>Can you please tell me the name of your dental insurance provider?</b>'+br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Adibot_What_Dental_Insurance__c) ? fbLead.Lead__r.Adibot_What_Dental_Insurance__c : '';
        strHTM += br() + '<b>Interested in finding out about our financing plans?</b>'+br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Adibot_Interested_Financing_Options__c) ? fbLead.Lead__r.Adibot_Interested_Financing_Options__c : '';
        strHTM += br() + '<b>Can you let me know how soon you\'re hoping to receive treatment?</b>'+br();
        strHTM +=  String.isNotBlank(fbLead.Lead__r.Adibot_How_Soon_Tooth_Replacement__c) ? fbLead.Lead__r.Adibot_How_Soon_Tooth_Replacement__c : '';
        strHTM += br() + br();
        strHTM += '==================' + br();
        strHTM += 'NEXT BEST ACTION' + br();
        strHTM += '==================' + br() + br();
        strHTM += '*You have a great opportunity to secure a new patient consultation by following up with this lead via text and/or phone call. ';
        strHTM += 'The included transcript provides details about the prospective patient to aid in your conversation. ' + br() + br();
        strHTM += '*HOT* Leads show indications of high conversion potential; if your lead is scored hot, make every effort to connect with this prospect as soon as possible. Don\'t miss your opportunity!' + br() + br();
        strHTM += '*WARM* Leads show moderate indications of conversion potential; if your lead is scored warm, attempt to connect with the prospect, but priority is not necessary do it when you have time!' + br() + br();
        strHTM += 'All leads are enrolled in an email follow-up plan to help warm them up and improve their conversion potential.' + br() + br();
        return strHTM;
    }
    
    private static String br() {
        return '<br/>';
    }
    
}