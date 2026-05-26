public class FacebookPatientMatch {
    
    private DateTime createdStart;
    private DateTime createdEnd;
    
    public FacebookPatientMatch(Date dtCreated) {
        createdStart = DateTime.newInstance(dtCreated, Time.newInstance(0,0,0,0));
        createdEnd = DateTime.newInstance(dtCreated + 1, Time.newInstance(0,0,0,0));
    }
    
    public Integer doMatchByEmailAddress() {
        
        List<Zeta_User__c> lstZetaUsers = this.getZetaUsers();
        Map<string,Zeta_user__c>  mapEmailtoZetaUser = this.getEmailToZetaUserMap(lstZetaUsers);
        
        Set<String> zEmails = this.getEmailSetFromZetaUsers(lstZetaUsers);
        List<FB_Lead__c> lstFbLeads = this.getFBLeadsByEmail(zEmails);  
        
        Map<String,FB_Lead__c> mapZtoL = this.getZetaUserToFBLeadByEmail(lstFbLeads,mapEmailToZetaUser);
        List<Zeta_Event__c> lstZEvents = this.getZetaEvents(mapZtoL);        
        List<FB_Lead__c> lstUpdate = this.getFirstApptsList(lstZEvents,mapZtoL);
        
        Database.SaveResult[] sr = Database.update(lstUpdate,false);
        return lstUpdate.size();        
    }   
    
    
    public Integer doMatchByPhone() {
        
        Integer intSize = 0;
        List<Zeta_User__c> lstZetaUsers = this.getZetaUsers();
        Map<string,Zeta_user__c>  mapPhonetoZetaUser = this.getPhoneToZetaUserMap(lstZetaUsers);
        
        Set<String> zPhones = this.getPhoneSetFromZetaUsers(lstZetaUsers);
        List<FB_Lead__c> lstFbLeads = this.getFBLeadsByPhone(zPhones);  
        
        Map<String,FB_Lead__c> mapZtoL = this.getZetaUserToFBLeadByPhone(lstFbLeads,mapPhonetoZetaUser);
        List<Zeta_Event__c> lstZEvents = this.getZetaEvents(mapZtoL);        
        List<FB_Lead__c> lstUpdate = this.getFirstApptsList(lstZEvents,mapZtoL);
        
        intSize = lstUpdate.size();
        System.debug(intSize);
        Database.SaveResult[] sr = Database.update(lstUpdate,false);
        return intSize;        
    }   
    
    
    public List<Zeta_User__c> getZetaUsers() {
        return [select id, user_Id__c,first_name__c,last_name__c, email__c, practice_id__c,phone_appointment__c,mobile_phone__c,home_phone__c,new_patient__c
                from Zeta_User__c
                where CreatedDate >=: createdStart 
                and CreatedDate <=: createdEnd
               ];
    }  
    
    public List<Zeta_Event__c> getZetaEvents( Map<String,FB_Lead__c> mapZetaToFbLead ) {
        return [select id, user_id__c,event_type__c,practiceid__c, apptid__c,apptdate__c, timestamp__c
                from zeta_event__c 
                   where CreatedDate >=: createdStart 
                and CreatedDate <=: createdEnd
                and user_id__c in: mapZetaToFbLead.keyset()
                order by timestamp__c];
    } 
    
    public Set<String> getEmailSetFromZetaUsers(List<Zeta_User__c> lstZU) {
        Set<String> zetaEmails = new Set<String>();
        for(Zeta_User__c zu: lstZU) {
            if(String.isNotBlank(zu.email__c))
                zetaEmails.add(zu.email__c);
        }
        return zetaEmails;
    }
    
    public Set<String> getPhoneSetFromZetaUsers(List<Zeta_User__c> lstZU) {
        Set<String> zetaPhones = new Set<String>();
        for(Zeta_User__c zu: lstZU) {
            if(String.isNotBlank(zu.phone_appointment__c))
                zetaPhones.add(zu.phone_appointment__c);
            
            if(String.isNotBlank(zu.mobile_phone__c)) 
                zetaPhones.add(zu.mobile_phone__c);
            
            if(String.isNotBlank(zu.home_phone__c)) 
                zetaPhones.add(zu.home_phone__c);
        }
        return zetaPhones;
    }
    
    public List<FB_Lead__c> getFBLeadsByEmail(Set<String> emails) {
        return [select id, FB_First_Name__c,FB_Last_Name__c,Fb_Email__c, FB_Phone_10__c,Practice_Id__c, Master_Patient_Id__c,
                First_Appointment_Id__c, First_Appointment_Date__c
                from FB_Lead__c where FB_Email__c in: emails];
    }
    
    public List<FB_Lead__c> getFBLeadsByPhone(Set<String> zPhones) {
        return [select id, FB_First_Name__c,FB_Last_Name__c,Fb_Email__c, FB_Phone_10__c, Practice_Id__c, Master_Patient_Id__c,
                First_Appointment_Id__c, First_Appointment_Date__c
                from FB_Lead__c where FB_Phone_10__c in: zphones];
    } 
    
    public Map<string,Zeta_user__c> getEmailToZetaUserMap(List<Zeta_User__c> lstZU) {
        Map<string,Zeta_user__c> mapEmailToZetaUser = new Map<String, Zeta_user__c>();
        for(Zeta_User__c zu: lstZU) {
            if(zu.email__c != null && zu.email__c != '') {
                mapEmailToZetaUser.put(zu.Email__c,zu);
            }
        }        
        return mapEmailToZetaUser;        
    }
    
    public Map<string,Zeta_User__c> getPhoneToZetaUserMap(List<Zeta_User__c> lstZU) {
        Map<string,Zeta_user__c> mapPhoneToZetaUser = new Map<String, Zeta_user__c>();
        for(Zeta_User__c zu: lstZU) {
            if(zu.phone_appointment__c != null && zu.phone_appointment__c != '') {
                mapPhoneToZetaUser.put(zu.phone_appointment__c,zu);
            }
            if(zu.mobile_phone__c != null && zu.mobile_phone__c != '') {
                mapPhoneToZetaUser.put(zu.mobile_phone__c,zu);
            }
            if(zu.home_phone__c != null && zu.home_phone__c != '') {
                mapPhoneToZetaUser.put(zu.home_phone__c,zu);
            }
        }        
        return mapPhoneToZetaUser;    
    }
    
    public Map<String,FB_Lead__c> getZetaUserToFBLeadByEmail(List<FB_Lead__c> lstFbLeads, Map<string,Zeta_user__c>  mapEmailtoZetaUser) {
        Map<String,FB_Lead__c> mapZetaUserToFBLead;
        mapZetaUserToFBLead = new Map<String,FB_Lead__c>();
        
        for(FB_Lead__c fb: lstFBLeads) {
            Zeta_User__c  zu = mapEmailtoZetaUser.get(fb.FB_Email__c);
            if(isEmailMatch(zu,fb)) {
                fb.Master_Patient_Id__c = zu.user_id__c;
                fb.New_Patient__c = Boolean.valueOf(zu.new_patient__c);
                mapZetaUserToFBLead.put(zu.user_id__c,fb);
            }
        }
        return mapZetaUserToFBLead;
    }
    
    public Map<String,FB_Lead__c> getZetaUserToFBLeadByPhone(List<FB_Lead__c> lstFbLeads,Map<string,Zeta_user__c>  mapPhonetoZetaUser) {
        
        Map<String,FB_Lead__c> mapZetaUserToFBLead;
        mapZetaUserToFBLead = new Map<String,FB_Lead__c>();
        
        for(FB_Lead__c fb: lstFBLeads) {
            Zeta_User__c  zu = mapPhonetoZetaUser.get(fb.FB_Phone_10__c);
            if(isPhoneMatch(zu,fb)) {
                fb.Master_Patient_Id__c = zu.user_id__c;
                fb.New_Patient__c = Boolean.valueOf(zu.new_patient__c);
                mapZetaUserToFBLead.put(zu.user_id__c,fb);
            }
        }
        return mapZetaUserToFBLead;
    }
    
    
    public List<FB_Lead__c>  getFirstApptsList(List<Zeta_Event__c> lstEvents, 
                                               Map<string,FB_Lead__c> mapZtoL) 
    {
        Set<Id>  fbids = new Set<Id>();
        List<FB_Lead__c> lstUpdate = new List<FB_Lead__c>();        
        
        for(Zeta_Event__c zEvent: lstEvents) {
            
            FB_Lead__c fbLead = mapZtoL.get(zEvent.user_id__c);
            
            if (fblead != null) {  
                if (zEvent.event_type__c == 'new_appt') {
                    if(fbLead.First_Appointment_Id__c == null) {
                        fblead.First_Appointment_Id__c = zEvent.apptid__c;
                        fblead.First_Appointment_Date__c = Date.parse(zEvent.apptdate__c);
                        fblead.First_Appointment_Trx__c = Date.valueOf(zEvent.timestamp__c.left(10));
                    }
                }
                else if (  zEvent.event_type__c == 'rescheduled_appt') {
                    if(zEvent.apptid__c == fbLead.First_Appointment_Id__c) {
                        fbLead.First_Appointment_Date__c = Date.parse(zEvent.apptdate__c);
                        fblead.First_Appointment_Trx__c = Date.valueOf(zEvent.timestamp__c.left(10));
                    }
                    
                }
                else if(zEvent.event_type__c == 'cancelled_appt' ) {
                    if(zEvent.apptid__c == fbLead.First_Appointment_Id__c) {
                        fblead.First_Appointment_Id__c = null;
                        fbLead.First_Appointment_Date__c = null;
                        fblead.First_Appointment_Trx__c = Date.valueOf(zEvent.timestamp__c.left(10));
                    }
                }
                else if (zEvent.event_type__c == 'deleted_appt') {
                    if(zEvent.apptid__c == fbLead.First_Appointment_Id__c) {
                        fblead.First_Appointment_Id__c = null;
                        fbLead.First_Appointment_Date__c = null;
                        fblead.First_Appointment_Trx__c = Date.valueOf(zEvent.timestamp__c.left(10));
                    }
                }
                
                if(fbids.add(fbLead.id)) {
                    lstUpdate.add(fblead);
                }
            }
        }
        
        return lstUpdate;
    }     
    
    public boolean isEmailMatch(Zeta_User__c zu,FB_Lead__c fb) {
        
        if(zu == null || fb == null)			       
            return false;
        
        if(zu.email__c == fb.FB_Email__c)
            return true;
        
        return false;
    }
    
    public boolean isPhoneMatch(Zeta_User__c zu,FB_Lead__c fb) {
        
        // if(zu == null || fb == null)				MN
        if(zu == null || fb == null || zu.first_name__c == null || zu.last_name__c == null)		//MN
            return false;
        
        if(zu.phone_appointment__c == fb.FB_Phone_10__c ||
           zu.mobile_phone__c == fb.FB_Phone_10__c ||
           zu.home_phone__c == fb.FB_Phone_10__c) {
               if(zu.first_name__c.tolowercase() == fb.FB_First_Name__c.tolowercase() &&
                  zu.last_name__c.tolowercase() == fb.FB_Last_Name__c.tolowercase())
                   return true;
           }
        
        return false;
    }
    
}