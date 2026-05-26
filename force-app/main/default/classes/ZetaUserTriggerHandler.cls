public class ZetaUserTriggerHandler {
    
    class JZetaUser {
        string user_id;
        string signed_up_at;
        string patient_id;
        string practice_id;
        string first_name;
        string last_name;
        contacts[] contacts;
        string home_phone;
        string mobile_phone;
        string work_phone;
        string phone_appointment;
        string street;
        string street2;
        string city;
        string state;
        string zip;
        string gender;
        string dob;
        string chartid;
        string new_patient;
        string dismissed;        
    }  
    
    class contacts {
        string contact_type;
        string contact_value;
    }
    
    public void beforeInsert(List<zeta_user__c> lstUser) {
        
        JZetaUser JUser;
        
        for(zeta_user__c user: lstUser) {
            try {
                
            JUser = (JZetaUser) JSON.deserialize(user.JSON__c,JZetaUser.class);
            
            user.user_id__c = JUser.user_id;
            user.signed_up_at__c= JUser.signed_up_at;
            user.patient_id__c= JUser.patient_id;
            user.practice_id__c= JUser.practice_id;
            user.first_name__c = JUser.first_name;
            user.last_name__c = JUser.last_name;
            user.home_phone__c = JUser.home_phone;
            user.mobile_phone__c = JUser.mobile_phone;
            user.phone_appointment__c = JUser.phone_appointment;
            user.street__c = JUser.street;
            user.street2__c = JUser.street2;
            user.city__c = JUser.city;
            user.state__c = JUser.state;
            user.zip__c = JUser.zip;
            user.gender__c = JUser.gender;
            user.dob__c = JUser.dob;
            user.chartid__c = JUser.chartid;
            user.new_patient__c = JUser.new_patient;
            user.dismissed__c = JUser.dismissed; 
            
            for(contacts c: JUser.contacts) {
                if(c.contact_type == 'email') {
                    user.email__c = c.contact_value.toLowerCase();
                }
            }
            
            if(user.practice_id__c != null)
                user.practice_id__c = user.practice_id__c.leftpad(5,'0');
            
           sanitizeZetaUser(user);
                
            user.Contact_Key__c = generateContactKey(user);

            
            }
            catch(Exception e) {
                
            }
        } 
    }
    
     @TestVisible
    private void sanitizeZetaUser(Zeta_User__c zUser) {
        if (zUser.phone_appointment__c != null) {
            String sanitizedPhone = zUser.phone_appointment__c.replaceAll('[^0-9]', '');
            if (sanitizedPhone.length() > 10) {
                sanitizedPhone = sanitizedPhone.substring(sanitizedPhone.length() - 10);
            }
            zUser.phone_appointment__c = sanitizedPhone;
        }

        if (zUser.practice_id__c != null) {
            String practiceId = zUser.practice_id__c.trim();
            if (practiceId.length() == 4 && Pattern.matches('\\d{4}', practiceId)) {
                practiceId = '0' + practiceId;
            }
            zUser.practice_id__c = practiceId;
        }
    }
    
    @TestVisible
    private String generateContactKey(Zeta_User__c z) {
        String first = z.first_name__c != null ? z.first_name__c.trim().toLowerCase() : '';
        String last = z.last_name__c != null ? z.last_name__c.trim().toLowerCase() : '';
        String phone = null;
        
        if (!String.isBlank(z.phone_appointment__c)) phone = z.phone_appointment__c;
        else if (!String.isBlank(z.mobile_phone__c)) phone = z.mobile_phone__c;
        else if (!String.isBlank(z.home_phone__c)) phone = z.home_phone__c;
        
        if (!String.isBlank(phone)) {
            String digits = phone.replaceAll('[^0-9]', '');
            phone = digits.length() > 10 ? digits.substring(digits.length() - 10) : digits;
            phone = phone.leftPad(10, '0');
        }
        
        String location = z.practice_id__c != null ? z.practice_id__c.trim() : '';
        return first + '-' + last + '-' + phone + '-' + location;
    }

}