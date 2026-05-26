@isTest
public class BatchFacebookPatientMatchTest {
    
    static List<Zeta_User__c> lstZU;
    static Map<string,Zeta_user__c>  mapEtoZ;
    static Map<string,Zeta_user__c> mapPtoZ ;
    static  Set<String> zEmails ;
    static Set<String> zPhones;
    static  List<FB_Lead__c> lstFB;
    static List<FB_Lead__c> lstFB2;
    static  boolean testmatch = false;
    static  Map<String,FB_Lead__c> mapZtoL ;
    static Map<String,FB_Lead__c> mapZtoL2 ;
    static List<Zeta_Event__c> lstZE;
    static List<FB_Lead__c> lstUpdate;
    static integer x;
    
    @isTest
    public static void testMatch() {
        
        //test data: zeta user
        Zeta_User__c zUser1 = new Zeta_User__c();
        zUser1.JSON__c = '{"user_id":"4779842","signed_up_at":"06/04/2018","patient_id":"33600","practice_id":"20123","first_name":"John","last_name":"Smith","contacts":[{"contact_type":"phone","contact_value":"9195551111"}],"home_phone":"9195151111","mobile_phone":"9195551111","work_phone":"","phone_appointment":"9195551111","street":"111 Shade Ln","street2":"","city":"Tampa","state":"FL","zip":"33617","gender":"m","dob":"1/1/1998","chartid":"034373","new_patient":"true","dismissed":"false"}';
        
        Zeta_User__c zUser2 = new Zeta_User__c();
        zUser2.JSON__c = '{"user_id":"5558421","signed_up_at":"06/04/2020","patient_id":"33601","practice_id":"01001","first_name":"Jane","last_name":"Doe","contacts":[{"contact_type":"email","contact_value":"janedoe@example.com"}],"home_phone":"9195551212","mobile_phone":"9195551212","work_phone":"","phone_appointment":"9195551212","street":"111 Shade Ln","street2":"","city":"Tampa","state":"FL","zip":"33617","gender":"m","dob":"12/21/1998","chartid":"034374","new_patient":"true","dismissed":"false"}';
        
        //test data: zeta event
        Zeta_Event__c zEvent = new Zeta_Event__c();
        zevent.JSON__c = '{"user_id":"5558421","event_type":"new_appt","timestamp":"2021-10-23T15:31:00Z","practiceid":"01001","apptid":"154905","apptdate":"10/29/2021","appttime":"08:00:00 AM","apptdatetime":"2021-10-29T12:00:00Z"}';
        
        //test data: zeta event
        Zeta_Event__c zEvent2 = new Zeta_Event__c();
        zevent2.JSON__c = '{"user_id":"4779842","event_type":"new_appt","timestamp":"2021-10-23T15:31:00Z","practiceid":"01001","apptid":"154903","apptdate":"10/29/2021","appttime":"011:00:00 AM","apptdatetime":"2021-10-29T11:00:00Z"}';
        
        //test data: facebook lead
        Account a = new Account(name='Asheville',Location_Id__c= '01001');
        insert a; 
        
        //matches zeta user 2
        FB_Lead__c fbLead1 = new FB_Lead__c();
        fbLead1.Fb_First_Name__c = 'Jane';
        fbLead1.FB_Last_Name__c = 'Doe';
        fbLead1.FB_Email__c = 'janedoe@example.com';
        fbLead1.FB_Practice__c = a.id;
        
        //matches zeta user 1
        FB_Lead__c fbLead2 = new FB_Lead__c();
        fbLead2.Fb_First_Name__c = 'John';
        fbLead2.FB_Last_Name__c = 'Smith';
        fbLead2.FB_Phone__c = '9195551111';
        fbLead2.FB_Practice__c = a.id;
        
        insert fbLead1;
        insert fbLead2;
        insert zUSer1;
        insert zUser2;
        insert ZEvent;
        insert ZEvent2;
        
        zUser1 = [select id, user_Id__c, first_name__c,last_name__c,email__c, practice_id__c,phone_appointment__c,mobile_phone__c,home_phone__c,new_patient__c from Zeta_User__c where id =: zUser1.id];
        zUser2 = [select id, user_Id__c, first_name__c, last_name__c, email__c, practice_id__c,phone_appointment__c,mobile_phone__c,home_phone__c,new_patient__c from Zeta_User__c where id =: zUser2.id];
        fbLead1 = [select id, FB_First_Name__c,FB_Last_Name__c,fb_email__c, FB_Phone_10__c, Practice_Id__c from fb_lead__c where id =: fbLead1.id];
        fbLead2 = [select id, FB_First_Name__c,FB_Last_Name__c,fb_email__c, FB_Phone_10__c, Practice_Id__c from fb_lead__c where id =: fbLead2.id];
        
        System.assertEquals('4779842',zUser1.user_id__c);
        System.assertEquals('5558421',zUser2.user_id__c);
        
        
        //list of zeta users
        BatchFacebookPatientMatch obj = new BatchFacebookPatientMatch('TODAY');
        lstZU = obj.getZetaUsers();
        System.assert(lstZU.size()>0);
        //email to zeta user map
        mapEtoZ = obj.getEmailToZetaUserMap(lstZU);
        System.assert(mapEtoZ.size() > 0);
        //phone to zeta user map
        mapPtoZ = obj.getPhoneToZetaUserMap(lstZU);
        System.assert(mapPtoZ.isEmpty()==false);
        //unique emails
        zEmails = obj.getEmailSetFromZetaUsers(lstZU);
        System.assert(zEmails.add('janedoe@example.com')==false);
        //unique phone set
        zPhones = obj.getPhoneSetFromZetaUsers(lstZU);
        System.assert(zPhones.add('9195551111') == false);
        //facebook leads by unique email
        lstFB = obj.getFBLeadsByEmail(zEmails);
        System.assert(lstFB.size() == 1);
        //facebook leads by phone
        lstFB2 = obj.getFBLeadsByPhone(zPhones);
        System.assert(lstFB.size() == 1);
        //test is match
        
        testmatch = obj.isEmailMatch(zUser1, fbLead1);
        System.assert(!testmatch);        
        testmatch = obj.isEmailMatch(zUser2, fbLead1);
        System.assert(testmatch);
        testmatch = obj.isPhoneMatch(zUser1, fbLead2);
        System.assert(testmatch);        
        testmatch = obj.isPhoneMatch(zUser2, fbLead2);
        System.assert(!testmatch);
        
        //zeta to fb lead maps
        mapZtoL = obj.getZetaUserToFBLeadByEmail(lstFB,mapEtoZ);
        fbLead1 = mapZtoL.get(zUser2.user_id__c);
        System.assertEquals(fbLead1.Master_Patient_Id__c,zUser2.user_id__c);
        System.assert(fbLead1.New_Patient__c);
        
        mapZtoL2 = obj.getZetaUserToFBLeadByPhone(lstFB2,mapPtoZ);
        fbLead2 = mapZtoL2.get(zUser1.user_id__c);
        System.assertEquals(fbLead2.Master_Patient_Id__c,zUser1.user_id__c); 
        System.assert(fbLead2.New_Patient__c);
        
        //zeta events
        lstZE = obj.getZetaEvents(mapZtoL);
        System.assert(lstZE.size() == 1);
        
        //update fb with first appt (using email map)
        String apptid;
        List<FB_Lead__c> lstUpdate = obj.getFirstApptsList(lstZE,mapZtoL);  
        for(FB_Lead__c fb: lstUpdate) {
            if(fb.id == fbLead1.id) {
                apptid = fb.First_Appointment_Id__c;
            }
        }
        
        System.assertEquals('154905',apptid);
        
        //zeta events
        lstZE  = obj.getZetaEvents(mapZtoL2);
        System.assert(lstZE.size() == 1);
        
        //update fb with first appt (using phone map)
        lstUpdate = obj.getFirstApptsList(lstZE,mapZtoL2);  
        for(FB_Lead__c fb: lstUpdate) {
            if(fb.id == fbLead2.id) {
                apptid = fb.First_Appointment_Id__c;
            }
        }
        
        System.assertEquals('154903',apptid);
        
        //main process
        x = obj.doMatchByEmailAddress(lstZU);
        System.assert(x == 1);
         x = obj.doMatchByPhone(lstZU);
        System.assert(x == 1);
        
        DataBase.executeBatch(obj); 
        
    }
}