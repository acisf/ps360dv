public class InsIntakeJob {
     
    //1pm get intakes from 7am-1pm,9:45pm get intakes from 1pm-9:00pm
    // pass in 0 for afternoon report
    // pass in 1 for evening report
    public static void runReports(Integer tod) {
        
        boolean debug = false;
        
        Time tmStart;
        Time tmEnd;
        
        //set start time and end time filter
        if(tod == 0) {
            tmStart = Time.newInstance(7, 0, 0, 0);
            tmEnd = Time.newInstance(13,0,0,0);
        }
        else if (tod == 1) {
            tmStart = Time.newInstance(13, 0, 0, 1);
            tmEnd = Time.newInstance(21,30,0,0);
        }
        
        Date dtDate = Date.today();
        DateTime dtStart = DateTime.newInstance(dtDate,tmStart);
        DateTime dtEnd = DateTime.newInstance(dtDate,tmEnd);
        
        system.debug(dtStart);
        system.debug(dtEnd);
        
        //get all insurance intakes
        List<Insurance_Intake__c> lstIntakes = getIntakes(dtStart,dtEnd);
        
        //unique practices
        Set<string> practiceLocationIds = getPracticesLocationIds(lstIntakes);
        Set<id> practiceIds = getPracticeIds(practiceLocationIds);
        
        //map account to fda                                                     
        Map<id,string> mapFDAs = getFDAs(practiceIds);   
        
        //map acount to name
        Map<id,string> mapNames = getPracticeNames(practiceIds);        
        
        //for each practice create html body
        Map<Id,string> mapBodies = new Map<Id,string>();
        for(String i:practiceIds) {
            string strHTML = getEmailBody(i,dtStart, dtEnd, lstIntakes);
            mapBodies.put(i,strHTML);
        }
        
        //for each practice create an email
        List<Messaging.Email> lstEmails;
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'patientsupport@affordablecare.com'];        
        lstEmails = new List<Messaging.Email>();
        
        for(Id practice:practiceIds) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
            List<String> toAddr = new List<String>();
            List<String> bccAddr = new List<String>();
            
            if(debug) {
                toAddr.add('douglas.vann@affordablecare.com');
                toAddr.add('DaShaya.Jett@affordablecare.com');
                 toAddr.add('tiffany.keith@affordablecare.com');
            } else {
                toAddr.add(mapFDAs.get(practice));
                bccAddr.add('douglas.vann@affordablecare.com');
            }
            
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            
            mail.setUseSignature(false);
            mail.setBCCSender(false);
            mail.toaddresses = toaddr;
            mail.bccaddresses = bccaddr;
            mail.setSubject('Insurance Intake Report - ' + mapNames.get(practice)) ;
            mail.setHTMLBody(mapBodies.get(practice));
            lstEmails.add(mail);
        }
        //send the emails
         Messaging.sendEmail(lstEmails,false);
    }
    
    
    public static List<Insurance_Intake__c> getIntakes (DateTime dtStart, DateTime dtEnd) {
        List<Insurance_Intake__c> lstIntakes = [select id,Location_Site__c,Appointment_Date__c,
                                                PatientFullName__c,Insurance_Carrier__c,Practice_Id__c,
                                                Subscriber_ID_Member_ID__c,Subscriber_Primary_Name__c,
                                                Patient_DOB__c,Subscriber_DOB_del__c,Group__c,Plan__c,Employer__c,CreatedDate
                                                from
                                                Insurance_Intake__c
                                                where Location_Site__c > '0'
                                                and CreatedDate >=: dtStart 
                                                and CreatedDate <=: dtEnd
                                                ORDER BY Location_Site__c, Appointment_Date__c];
        system.debug(lstIntakes);
        return lstIntakes;
    }
    
    //return unique set of practices
    public static Set<string> getPracticesLocationIds(List<Insurance_Intake__c> lstIntake ) {
        Set<string> practices = new set<string>();
        for(Insurance_Intake__c i:lstIntake) {
            practices.add(i.Location_Site__c);
        }
        return practices;        
    }
    
    //return unique set of practices
    public static Set<Id> getPracticeIds(Set<string> practiceLocationIds ) {
        Set<Id> practices = new Set<Id>();
        List<account> lstAccount = [select id from account where location_id_5_digit__c in:practiceLocationIds];
        for(Account a:lstAccount) {
            practices.add(a.id);
        }
        return practices;        
    }
    //return fda email for each practice
    public static Map<Id,string> getFDAs(Set<id> PracticeIds ) {
        Map<Id,string> mapFDAs = new Map<Id,string>();
        List<Account> lstA = new List<Account>();
        lstA = [select id,FDA_Email__c
                from Account
                where id in:PracticeIds];
        
        for(Account a: lstA) {
            mapFDAs.put(a.id,a.FDA_Email__c);
        }
        return mapFDAs;        
    }
    //return name for each practice
    public static Map<Id,string> getPracticeNames (Set<id> PracticeIds ) {
        Map<Id,string> mapnames = new Map<Id,string>();
        List<Account> lstA = new List<Account>();
        lstA = [select id,name, Location_Id_5_Digit__c
                from Account
                where id in:PracticeIds];
        
        for(Account a: lstA) {
            mapnames.put(a.id, a.Location_ID_5_digit__c + ' ' +  a.name );
        }
        return mapnames;        
    }
    
    //return html body for each practice
    public static string getEmailBody(Id practiceid, DateTime dStart, DateTime dEnd, list<insurance_intake__c> lstI ) {
        string strHTM;
        strHTM = '<html>'; 
        strHTM += '<h3>Insurance Intake Report</h3>';
        strHTM += 'Run at: ' + DateTime.now().format() + '<br>'; 
        strHTM += 'Filtered by: Created date between ' + dStart.format() + ' and ' + dEnd.format();
        strHTM += '<br/><br/>';
        strHTM += '<table style="border:1px solid #cccccc" cellspacing="0" cellpadding="5" border="none">'; 
        strHTM += '<tr>';
        strHTM += '<td style="background: #AAAAFF;">Location</td>';
        strHTM += '<td style="background: #AAAAFF;">Appointment Date</td>';
        strHTM += '<td style="background: #AAAAFF;">Patient Name</td>';
        strHTM += '<td style="background: #AAAAFF;">Patient DOB</td>';
        strHTM += '<td  style="background: #AAAAFF;">Insurance Carrier</td>';
        strHTM += '<td  style="background: #AAAAFF;">Subscriber Id</td>';
        strHTM += '<td style="background: #AAAAFF;">Subscriber Name</td>';
        strHTM += '<td style="background: #AAAAFF;">Subscriber DOB</td>';
        strHTM += '<td style="background: #AAAAFF;">Group</td>';
        strHTM += '<td style="background: #AAAAFF;">Plan</td>';
        strHTM += '<td style="background: #AAAAFF;">Employer</td>';
        strHTM += '<td style="background: #AAAAFF;">Created Date</td>';
        strHTM += '</tr>';
        
        for(insurance_intake__c i:lstI) {
            
            if(i.Practice_Id__c == practiceid) {
                strHTM += '<tr>';
                strHTM += '<td>' + i.Location_Site__c + '</td>';
                
                if(i.Appointment_Date__c != null) {
                     strHTM += '<td>' + i.Appointment_Date__c.format() + '</td>';
                } else
                {
                     strHTM += '<td>' + i.Appointment_Date__c + '</td>';
                }
                
                strHTM += '<td>' + i.PatientFullName__c + '</td>';
                
                 if(i.Patient_DOB__c != null) {
                     strHTM += '<td>' + i.Patient_DOB__c.format() + '</td>';
                } else
                {
                     strHTM += '<td>' + i.Patient_DOB__c + '</td>';
                }
                
                strHTM += '<td>' + i.Insurance_Carrier__c + '</td>';
                strHTM += '<td>' + i.Subscriber_ID_Member_ID__c + '</td>';
                strHTM += '<td>' + String.valueOf(i.Subscriber_Primary_Name__c) + '</td>';
                
                if(i.Subscriber_DOB_del__c != null) {
                     strHTM += '<td>' + i.Subscriber_DOB_del__c.format() + '</td>';
                } else
                {
                     strHTM += '<td>' + i.Subscriber_DOB_del__c + '</td>';
                }
               
                strHTM += '<td>' + String.valueOf(i.Group__c) + '</td>';
                strHTM += '<td>' + String.valueOf(i.Plan__c) + '</td>';
                strHTM += '<td>' + String.valueOf(i.Employer__c) + '</td>';
                strHTM += '<td>' + i.CreatedDate.format() + '</td>';
                strHTM += '</tr>';
            }
        }
        
        strHTM += '</table></html>';
        return strHTM;
        
    } 
}