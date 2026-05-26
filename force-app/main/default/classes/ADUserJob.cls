public class ADUserJob {
    
/***********
example usage
***********/
/*
DateTime dt = DateTime.newInstance(Date.today(),Time.newInstance(0,0,0,0));
adUserJob.runJob(dt)
*/
    
    public static void runJob(DateTime dtStart) {       
        
/*************
EXISTING SF Users 
*************/ 
        
        set<string> emails = new set<string>();
        map<string,user> mapuser = new map<string,user>();
        map<string,contact> mapcontact = new map<string,contact>();
        list<contact> listContactUpd = new list<contact>();
        list<user> listUserUpd = new list<user>();
         Database.SaveResult[] sr;
        
        list<Ad_user__c> lstAD = [select id,Name, Active__c,
                                  location_id__c,Contact__c,Department__c,
                                  email__c,First_Name__c,Group__c,
                                  Job_Title__c,Last_Name__c,
                                  Phone_Number__c,PracticeDescription__c,
                                  Lastmodifieddate
                                  from AD_user__c
                                  where LastModifiedDate >=: dtStart];
        
        for(Ad_User__c ad:lstAD) {
            emails.add(ad.email__c.tolowercase().replace('?',''));
        }
        
        list<user> lstUser = [select id, email,firstName,lastName,Department,title,Phone,isActive,lastmodifieddate,
                              contactId
                              from user
                              where email in:emails];
        
        for(user u: lstUser) {
            mapuser.put(u.email,u);
        }
        
        for(Ad_User__c ad:lstAD) {
            if(mapuser.get(ad.email__c.toLowerCase().replace('?','')) !=null) {
                User u = mapuser.get(ad.email__c.toLowerCase().replace('?',''));
				ad.user__c = u.id;
                ad.status__c = 'Existing User';
                if(u.FirstName != ad.First_Name__c) {
                    u.FirstName = ad.First_Name__c;
                    ad.Status__c += '\nUpdated: First Name';
                }
                if(u.LastName != ad.Last_Name__c) {
                    u.LastName = ad.Last_Name__c;
                    ad.Status__c += '\nUpdated: Last Name';
                }
                if(u.Phone != ad.Phone_Number__c) {
                    u.Phone = ad.Phone_Number__c;
                    ad.Status__c += '\nUpdated: Phone';
                }
                if( u.Department != ad.Department__c) {
                    u.Department = ad.Department__c;
                    ad.Status__c += '\nUpdated: Department';                        
                }	
                if( u.Title != ad.Job_Title__c) {
                    u.Title = ad.Job_Title__c;
                    ad.Status__c += '\nUpdated: Title';                        
                }	
                if(u.IsActive != ad.Active__c) {
                    u.IsActive = ad.Active__c; 
                    ad.Status__c += 'Updated: Active to ' + String.valueOf(ad.Active__c);
                }
                if(ad.Status__c != 'Existing User') {
                    listuserupd.add(u);
                }                
            }
        }
        
/****************
EXISTING SF Contacts  
****************/
        mapuser = null;
        mapcontact = new map<string,contact>();
        
        list<contact> lstC = [select id, email, FirstName, LastName, AccountId, Department, Description,
                              Work_Phone__c, Title, Active_Contact__c,LastModifiedDate
                              from contact
                              where email in:emails];
        
        for(contact c: lstC) {
            mapcontact.put(c.email,c);
        }
        
        for(Ad_User__c ad:lstAD) {
            if(mapcontact.get(ad.email__c.toLowerCase().replace('?','')) !=null) {
                Contact c = mapcontact.get(ad.email__c.toLowerCase().replace('?',''));
                ad.contact__c = c.id;
                ad.status__c = 'Existing Contact';
                
                if(c.FirstName != ad.First_Name__c) {
                    c.FirstName = ad.First_Name__c;
                    ad.Status__c += '\nUpdated: First Name';
                }
                if(c.LastName != ad.Last_Name__c) {
                    c.LastName = ad.Last_Name__c;
                    ad.Status__c += '\nUpdated: Last Name';
                }
                if(c.Work_Phone__c != ad.Phone_Number__c) {
                    c.Work_Phone__c = ad.Phone_Number__c;
                    ad.Status__c += '\nUpdated: Work Phone';
                }
                if( c.Department != ad.Department__c) {
                    c.Department = ad.Department__c;
                    ad.Status__c += '\nUpdated: Department';                        
                }	
                if( c.Title != ad.Job_Title__c) {
                    c.Title = ad.Job_Title__c;
                    ad.Status__c += '\nUpdated: Title';                        
                }	
                if(c.Description != ad.PracticeDescription__c) {
                    c.Description = ad.PracticeDescription__c;
                    ad.Status__c += '\nUpdated: Practice/Description'; 
                }
                if(c.Active_Contact__c != ad.Active__c) {
                    c.Active_Contact__c = ad.Active__c; 
                    ad.Status__c += 'Updated: Active to ' + String.valueOf(ad.Active__c);
                }
                if(ad.Status__c != 'Existing Contact') {
                    listcontactupd.add(c);
                }  
            }
        }
        
        update lstAD;        
        sr = Database.update (listUserUpd,false);
        sr = Database.update (listContactUpd,false);        
       
        
/************************
new practice employees 
************************/
        
        Id pid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Practice Employee').getRecordTypeId();
        list<contact> lstNewContacts = new List<Contact>();        
        lstAD = [select id,Name, Active__c,
                 location_id__c,Contact__c,Department__c,
                 email__c,First_Name__c,Group__c,
                 Job_Title__c,Last_Name__c,
                 Phone_Number__c,PracticeDescription__c
                 from ad_user__c
                 where contact__c = null and
                 location_id__c != '0' and
                 LastModifiedDate >=: dtStart];
        
        emails = new set<string>();
        set<string> locations = new set<string>();
        map<string,id> mapaccount = new map<string,id>();
        map<string,id> mapcontacts = new map<string,id>();
        
        for(Ad_User__c ad:lstAD) {
            emails.add(ad.email__c.tolowercase().replace('?',''));
            locations.add(ad.Location_Id__c);
        }
        
        list<account> lstA = [select id, location_id_5_digit__c from account
                              where location_id_5_digit__c in: locations];
        
        for(account a: lstA) {
            mapaccount.put(a.location_id_5_digit__c,a.id);
        }
        
        for(Ad_User__c ad:lstAD) {
            Contact c = new Contact();
            c.recordtypeid = pid;
            c.AccountId = mapaccount.get(ad.Location_id__c);
            c.FirstName = ad.First_Name__c;
            c.LastName = ad.Last_Name__c;
            c.Email = ad.email__c.tolowercase().replace('?','');
            c.Department = ad.Department__c;
            c.Type__c = ad.Job_Title__c;
            c.Title = ad.Job_Title__c;
            c.Description = ad.PracticeDescription__c;
            c.Active_Contact__c = ad.Active__c;
            c.Work_Phone__c = ad.Phone_Number__c;
            lstNewContacts.add(c);
        }
        
        //sr = Database.insert (lstNewContacts,false);
        //MN
        Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 		
		sr = Database.insert(lstNewContacts, dml);
        
        for (Database.SaveResult s : sr) {
            if (!s.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : s.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        for(Contact c:lstNewContacts) {
            mapcontacts.put(c.email,c.id);
        }
        
        for(Ad_User__c ad:lstAD) {
            if(mapcontacts.get(ad.email__c.toLowerCase().replace('?','')) !=null) {
                ad.contact__c = mapcontacts.get(ad.email__c.toLowerCase().replace('?',''));
                ad.status__c = 'inserted practice contact';
            }
        }
        
        update lstAD;
        
/***************
new ac employees
****************/
        
        Id cid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Corporate Employee').getRecordTypeId();
        lstNewContacts = new List<Contact>();
        lstAD = [select id,Name,Active__c,
                 location_id__c,Contact__c,Department__c,
                 email__c,First_Name__c,Group__c,
                 Job_Title__c,Last_Name__c,
                 Phone_Number__c,PracticeDescription__c
                 from ad_user__c
                 where contact__c = null and
                 LastModifiedDate >=: dtStart and
                 location_id__c = '0'];
        
        emails = new set<string>();
        locations = new set<string>();
        mapaccount = new map<string,id>();
        mapcontacts = new map<string,id>();
        
        
        id accountid;
        lstA = [select id, location_id_5_digit__c from account
                where name = 'Affordable Care, LLC'];
        
        for(account a: lstA) {
            accountid = a.id;
        }
        
        
        for(Ad_User__c ad:lstAD) {
            Contact c = new Contact();
            c.recordtypeid = cid;
            c.AccountId = accountid;
            c.FirstName = ad.First_Name__c;
            c.LastName = ad.Last_Name__c;
            c.Email = ad.email__c.tolowercase().replace('?','');
            c.Department = ad.Department__c;
            c.Type__c = ad.Job_Title__c;
            c.Title = ad.Job_Title__c;
            c.Description = ad.PracticeDescription__c;
            c.Active_Contact__c = ad.Active__c;
            c.Work_Phone__c = ad.Phone_Number__c;
            lstNewContacts.add(c);
        }
        
        sr = Database.insert (lstNewContacts,false);
        
        for(Contact c:lstNewContacts) {
            mapcontacts.put(c.email,c.id);
        }
        
        for(Ad_User__c ad:lstAD) {
            if(mapcontacts.get(ad.email__c.toLowerCase().replace('?','')) !=null) {
                ad.contact__c = mapcontacts.get(ad.email__c.toLowerCase().replace('?',''));
                ad.Status__c = 'inserted corporate contact';
            }
        }
        
        update lstAD;        
    }
}