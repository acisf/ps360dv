/*This job runs at 00:01 and queries fees/services calls and inserts object for the Call-No-Appointment campaign.
The campaign is 3 follow-up emails or phone calls over 7 days and direct mail after 30 days,
for new patients who called about fees/services but did not schedule and appt 
*/

public class CnaJob {
    
    public static List<CNA_Tracking__c> lstNewTracking;    
    public static List<CNA_Tracking__c> lstAppointed; 
    public static List<CNA_RobocallOptout__c> lstRoboCallOptOuts;
    public static List<CNA_Tracking__c> lstDoNotEmail;
    public static List<CNA_Tracking__c> lstDoNotCall;
    public static List<CNA_Tracking__c> lstDirectMail;
    public static List<Integer> lstRandom;
    public static DateTime calldate = DateTime.newInstance(Date.today()-1, Time.newInstance(0,0,0,0)); 
    
    @future
    public static void tracking() {
        insertCNATracking();
    }
    
    @future
    public static void appointed() {        
        updateScheduled();        
    }
    
    @future 
    public static void  emailoptouts() {
        updateEmailOptOuts();  
    }
    
    @future 
    public static void  robocalloptouts() {
        updateRoboCallOptOuts();  
    }

    
    //insert tracking objects    
    public static void insertCNATracking() { 
        
        List<NVMStatsSF__NVM_Call_Summary__c>lstCNACallsTemp; 
        List<NVMStatsSF__NVM_Call_Summary__c>lstNewCNACalls; 
        List<NVMStatsSF__NVM_Call_Summary__c>lstScheduleCalls;
        List<CNA_Tracking__c> lstExistingTracking;
        Set<id> contactids; 
        
        lstCNACallsTemp = new List<NVMStatsSF__NVM_Call_Summary__c>();    
        lstNewCNACalls = new List<NVMStatsSF__NVM_Call_Summary__c>();
        lstScheduleCalls = new List<NVMStatsSF__NVM_Call_Summary__c>();
        lstExistingTracking = new List<CNA_Tracking__c>(); 
        contactids = new set<id>(); 
        
        //calls where patient inquired about fees/services
        lstCNACallsTemp = [SELECT Id,
                           NVMStatsSF__CallTime__c,
                           NVMStatsSF__Related_Contact__c,
                           NVMStatsSF__Related_Contact__r.Email,
                           NVMStatsSF__Related_Contact__r.HasOptedOutOfEmail,
                           NVMStatsSF__Related_Contact__r.DoNotCall,
                           NVMStatsSF__Related_Contact__r.Do_Not_Mail__c,   
                           NVMStatsSF__Related_Contact__r.Account.CNA_EmailOptIn__c,   
                           NVMStatsSF__Related_Contact__r.Account.CNA_RoboCallOptIn__c,   
                           NVMStatsSF__Related_Contact__r.Account.CNA_DirectMailOptIn__c               
                           FROM NVMStatsSF__NVM_Call_Summary__c 
                           WHERE NVMStatsSF__Interaction_Type__c = 'Inbound Call'
                           AND NVMStatsSF__CallDisposition__c =: 'Fees/Services'
                           AND NVMStatsSF__Related_Contact__r.Account.Record_Type__c =: 'Schedule Assist'
                           AND NVMStatsSF__Related_Contact__r.FirstName != 'Unidentified'
                           AND NVMStatsSF__CallTime__c >: calldate
                           AND NVMStatsSF__CallTime__c <: (calldate +1)];
        
        system.debug(lstcnacallstemp.size());
        
        //set of contact ids
        for(NVMStatsSF__NVM_Call_Summary__c call:lstCNACallsTemp) {
            contactids.add(call.NVMStatsSF__Related_Contact__c);
        } 
        
        
        //contacts tracked already 
        lstExistingTracking = [SELECT id,cna_contact__c, cna_age__c,CNA_InitialCallTime__c
                               FROM cna_tracking__c 
                               WHERE cna_contact__c in:contactids ];
        
        for(CNA_Tracking__c t:lstExistingTracking) { 
            if(t.CNA_InitialCallTime__c >= (Date.today() -60))
            		contactids.remove(t.CNA_Contact__c); 
            else
                t.CNA_ContactId__c = null;            
        }
        
        
        //contacts that have scheduled before
        lstScheduleCalls = [SELECT NVMStatsSF__Related_Contact__c
                            FROM NVMStatsSF__NVM_Call_Summary__c 
                            WHERE NVMStatsSF__CallDisposition__c =: 'Scheduled'
                            AND NVMStatsSF__Related_Contact__c IN: contactids];
        for(NVMStatsSF__NVM_Call_Summary__c call:lstScheduleCalls) {
            contactids.remove(call.NVMStatsSF__Related_Contact__c);
        }        
        
        
        
        //final list based on contactids        
        for(NVMStatsSF__NVM_Call_Summary__c call: lstCNACallsTemp) {
            if(contactids.contains(call.NVMStatsSF__Related_Contact__c)) {
                lstNewCNACalls.add(call);
            }
        }
        
        Integer callCount = 0;
        lstRandom = new List<Integer>();
        lstNewTracking = new List<CNA_Tracking__c>();  
        
        for(NVMStatsSF__NVM_Call_Summary__c summary:lstNewCNACalls) {
            
            CNA_Tracking__c tracking = new CNA_Tracking__c();
            tracking = new CNA_Tracking__c();
            tracking.CNA_Initial_Call__c = summary.Id;
            tracking.CNA_InitialCallTime__c = summary.NVMStatsSF__CallTime__c;
            tracking.CNA_Contact__c = summary.NVMStatsSF__Related_Contact__c;
            tracking.CNA_ContactId__c = summary.NVMStatsSF__Related_Contact__c;  
            tracking.CNA_Status__c = 'Zeta';
            /*tracking.CNA_Status__c = '';
            
            if((summary.NVMStatsSF__Related_Contact__r.Account.CNA_EmailOptIn__c ||
                summary.NVMStatsSF__Related_Contact__r.Account.CNA_DirectMailOptIn__c) &&
                !String.isEmpty(summary.NVMStatsSF__Related_Contact__r.Email) && 
               !summary.NVMStatsSF__Related_Contact__r.HasOptedOutOfEmail) {
                tracking.CNA_Status__c = 'Email';
            }
            else if((summary.NVMStatsSF__Related_Contact__r.Account.CNA_RobocallOptIn__c ||
                	summary.NVMStatsSF__Related_Contact__r.Account.CNA_DirectMailOptIn__c) && 
                    !summary.NVMStatsSF__Related_Contact__r.DoNotCall) {
                	tracking.CNA_Status__c = 'Robocall';
            }
            else {
                tracking.CNA_Status__c = 'Optout';
            }       */         
            
            lstNewTracking.add(tracking); 
            lstRandom.add(callCount);
            callCount += 1;
        }  
        
        //create a list of random numbers, then trim it to the sample size of 10%
        Integer intSampleSize = lstNewTracking.size() / 10;     
        lstRandom = randomize(lstRandom);           
        lstRandom = getSubset(lstRandom, intSampleSize);        
        
        //create a control group
        //callcount = 0;
        //for(cna_tracking__c tracking:lstNewTracking) {
        //    if(lstRandom.contains(callCount)) {
        //        tracking.CNA_Status__c = 'Control Group';
        //    }
        //    callcount +=1;
       // }
        
        //do the insert  
        Database.SaveResult[] sr = Database.update(lstExistingTracking,false);
        sr = Database.insert(lstnewtracking,false);
    }
    
    //change state to Appointed if patient schedules   
    public static void updateScheduled() {
        
        List<NVMStatsSF__NVM_Call_Summary__c>lstScheduleCalls; 
        set<id> contactids;
        map<id,NVMStatsSF__NVM_Call_Summary__c> schedulecallmap;
        
        lstScheduleCalls = new List<NVMStatsSF__NVM_Call_Summary__c>(); 
        contactids = new Set<id>();
        schedulecallmap = new map<id,NVMStatsSF__NVM_Call_Summary__c>();
        
        //get calls where patients scheduled yest
        lstScheduleCalls = [SELECT Id,NVMStatsSF__Related_Contact__c, NVMStatsSF__CallTime__c
                            FROM NVMStatsSF__NVM_Call_Summary__c 
                            WHERE NVMStatsSF__CallDisposition__c =: 'Scheduled'
                            AND NVMStatsSF__CallTime__c >: calldate
                            AND NVMStatsSF__CallTime__c <: (calldate +1)];
        
        System.debug(lstScheduleCalls);
        
        for(NVMStatsSF__NVM_Call_Summary__c call:lstScheduleCalls) {
            contactids.add(call.NVMStatsSF__Related_Contact__c);
            schedulecallmap.put(call.NVMStatsSF__Related_Contact__c,call);
        }
        
        //get tracking objects
        lstAppointed = [SELECT Id, CNA_Status__c,CNA_Conversion_Call__c,cna_contact__c,
                        CNA_InitialCallTime__c,CNA_Conversion_Date__c
                        FROM CNA_Tracking__c 
                        WHERE CNA_Contact__c IN: contactids
                        AND (CNA_Status__c = 'Email' OR CNA_Status__c = 'Robocall' OR CNA_Status__c = 'Direct Mail')];
        
        //convert the tracking if found
        for(CNA_Tracking__c cna: lstAppointed) {
            if(schedulecallmap.get(cna.cna_contact__c) != null) {
                NVMStatsSF__NVM_Call_Summary__c call = schedulecallmap.get(cna.cna_contact__c);
                if(cna.CNA_InitialCallTime__c < call.NVMStatsSF__CallTime__c) {
                    cna.CNA_Conversion_Call__c = call.Id;
                    cna.CNA_Conversion_Date__c = call.NVMStatsSF__CallTime__c;
                    cna.CNA_Status__c = 'Appointed';
                }
            }            
        }          
        
        Database.SaveResult[] sr = Database.update(lstAppointed,false);        
        
    }
    
    //change state to robocall if patient opts out of email or email bounces
    public static void updateEmailOptOuts() {
        Database.SaveResult[] sr;  
        
        //get contacts who bounced or opted out of email
        lstDoNotEmail = new List<CNA_Tracking__c>();     
        lstDoNotEmail = [SELECT Id, CNA_Status__c	
                         FROM CNA_Tracking__c 
                         WHERE 
                         CreatedDate >=: DateTime.now() - 31
                         AND CNA_Status__c =: 'Email'                         
                         AND (CNA_Tracking__c.CNA_Contact__r.HasOptedOutOfEmail =: true
                              OR CNA_Tracking__c.CNA_Contact__r.EmailBouncedDate != null)];
        //and switch their status to Robocall        
        for(CNA_Tracking__c cna : lstDoNotEmail) {
            cna.CNA_Status__c = 'Robocall';
        }  
        sr = Database.update(lstDoNotEmail,false);                
    }   
    
    //get contacts who opted out of phone calls
    public static void updateRoboCallOptOuts() {
        
        Database.SaveResult[] sr; 
        Set<string> phones = new Set<string>();
        List<Contact> lstContacts = new List<Contact>();
        
        lstRoboCallOptOuts = [SELECT Phone__c, Processed__c 
                              FROM CNA_RobocallOptout__c
                              WHERE Processed__c =: false];
        
        for(CNA_RobocallOptout__c optout: lstRoboCallOptOuts) {
            phones.add(optout.Phone__c);
            optout.Processed__c = true;
        }
        
        lstContacts = [SELECT Id, DoNotCall
                       FROM Contact
                       WHERE HomePhone IN: phones];
        
        for(Contact c:lstContacts) {
            c.DoNotCall = true;
        }     
        
        sr = Database.update(lstContacts,false);
        sr = Database.update(lstRoboCallOptOuts,false); 
    }    
      
    public static list<Integer> randomize(list<Integer> lst){
        integer currentIndex = lst.size();
        integer tmp;
        integer randomIndex;
        
        while (0 != currentIndex) {
            
            randomIndex = integer.valueOf(Math.floor(Math.random() * currentIndex));
            currentIndex -= 1;
            
            tmp = lst[currentIndex];
            lst[currentIndex] = lst[randomIndex];
            lst[randomIndex] = tmp;
        }
        
        return lst;
    }
    
    public static List<Integer> getSubSet(list<Integer> lst, Integer intSampleSize) {
        List<Integer> lstSubset = new List<Integer>();
        for(Integer x = 0;x<intSampleSize;x++) {
            lstSubset.add(lst[x]);
        }
        
        return lstSubset;
    }
    
    public static void truncateExistingPatientTemp() {
        List<CNA_ExistingPatientTmp__c> lstP = new List<CNA_ExistingPatientTmp__c>();
        lstP = [SELECT Id FROM CNA_ExistingPatientTmp__c];
        delete lstP;
    } 
}