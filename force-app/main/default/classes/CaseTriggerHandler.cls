public class CaseTriggerHandler {
    
    public void beforeInsert(list<case> lstNew){
        
        List<case> lstDupe = new List<Case>();
        List<Case> lstCases = new List<Case>();
        Set<string> rgsubjects = new Set<String>();   
        Map<string,case> rgMap = new Map<string,case>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> locationIds = new Set<String>();
        Map<String,Case> mapWebEmailCase = new Map<String,Case>();
        
        Boolean blnRunDupeCheck = false;  
        Boolean blnScanSubject = false;
        
        for(Case c: lstNew){
            if(c.SuppliedEmail != null && c.SuppliedEmail != '')
                mapWebEmailCase.put(c.SuppliedEmail, c);
        }
        
        if (mapWebEmailCase.size() > 0)
            checkEmailIsBlockedFromCreatingCase(mapWebEmailCase);
        
        for(Case c: lstNew) {
            
            if (isRecordType(c, 'SDEmail') || isRecordType(c, 'Marketing Support') || isRecordType(c, 'SevaredentPurchasing')) {
                blnScanSubject = true;
                lstCases.add(c);
                accountIds.add(c.AccountId);
                String[] locationid = getLocationFromSubject(c.Subject);
                
                for (String loc : locationid) {
                    if (String.isNotBlank(loc)) {                                           
                        if (loc.length() < 5)
                            loc = '0' + loc;                        
                        locationIds.add(loc);
                    }    
                }
            } else if (isRecordType(c, 'RedGate')) {
                if (rgSubjects.add(c.Subject)) {
                    rgMap.put(c.Subject, c);
                    blnRunDupeCheck = true;
                } else {
                    c.addError('Duplicate RedGate case [debug code csae1]'); 
                }                    
            }
        }
        if(blnRunDupeCheck) {
            lstDupe = getRedgateDupes(rgSubjects);  
            for(Case c: lstDupe) {
                if(rgMap.get(c.Subject) != null) {
                    Case rgCase = rgMap.get(c.Subject);
                    rgCase.addError('Duplicate RedGate case [debug code csae2]');
                }
            }
        }
        
        if(blnScanSubject) {
            
            System.debug('Account Ids'); system.debug(accountIds);system.debug('Location Ids');system.debug(locationIds);
            
            Map<Id,Account> mapPractices = getPracticeMap(accountIds);
            Map<String,Account> mapLocation = getLocationMap(locationIds);
            
            System.debug('Map Practices');system.debug(mapPractices);system.debug('Map Subj Locations');system.debug(mapLocation);
            
            for(Case c: lstCases) { 
                Boolean validPractice = mapPractices.get(c.AccountId) != null; 
                
                system.debug('valid practice?');System.debug(validPractice);
                
                if(!validPractice) {
                    string[] locations = getLocationFromSubject(c.Subject); 
                    
                    for(string loc:locations) {
                        if(loc.length() < 5)
                            loc = '0' + loc;
                        
                        system.debug('trying location from subject: ' + loc);
                        if(mapLocation.get(loc) != null) {
                            system.debug('Successfully found in mapLocation: ' + loc);
                            c.AccountId = mapLocation.get(loc).Id;
                            System.debug('Updating account id to ' + c.AccountId);
                            
                        }
                    }
                }
            }
        }
        
    }
    
    public void afterInsert(list<case> lstNew){ 
        
        Set<Id> accountids = new Set<Id>();
        Set<Id> caseids = new Set<Id>();
        List<Account> lstAccounts;
        Map<Id,Account> mapAccounts;
        List<Case> lstNewCases;
        
        for(Case c:lstNew) {
            accountids.add(c.AccountId);
            caseids.add(c.Id);
        }
        
        mapAccounts = getPracticeMap(accountids);
        lstNewCases = [Select id, AccountId, Origin, Location_Found__c, recordtypeid from Case
                       Where id in :caseids];        
        
        for(Case c: lstNewCases) {
            if(c.Origin == 'MyPractice') {
                c = addDMLOptionToCase(c);
            }
            
            if(isRecordType(c,'SevaredentPurchasing') && mapAccounts.get(c.AccountId) !=null) {
                c.Location_Found__c = true;
            }
        }  
        
        update lstNewCases;
        
        
    }
    
    public Case addDMLOptionToCase(Case c) {
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.emailHeader.triggerAutoResponseEmail = true;
        dmo.emailHeader.triggerUserEmail = true;
        c.setOptions(dmo);        
        return c;
    }
    
    
    public void beforeUpdate(list<case> lstNew,list<case> lstOld){   
    }
    
    public void afterUpdate(list<case> lstNew,list<case> lstOld){  
        
        if(checkRecursive.runOnce()) {
            List<Case> lstCases = new List<Case>();
            List<User> lstUsers = new List<User>();
            Set<Id> caseIds = new Set<Id>();
            User usr;

            for(Case c: lstNew) {
                caseIds.add(c.id);
            }
            
            lstCases = [SELECT Id, Queue_Name__c FROM Case WHERE Id IN: caseIds AND RecordType.Name = 'ACE Service' AND Queue_Name__c = ''];
            
            if(lstCases.Size() > 0 ) {
                Id userId = UserInfo.getUserId();
                lstUsers = [SELECT Id, Primary_Queue__c FROM User WHERE Id =: userId LIMIT 1];
                for(User u: lstUsers) {
                    usr = u;
                }
                if(lstUsers.size() > 0 && String.isEmpty(usr.Primary_Queue__c) && lstCases.size() > 0 ) {
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.AssignmentRuleHeader.useDefaultRule = TRUE;
                    Database.update (lstCases,dmo);
                }
            }
            
        }
    }
    
    public  Map<Id,Account> getPracticeMap(Set<Id> accid) {
        Map<Id,Account> accmap = new Map<Id,Account>();
        if(accid != null) 
            accmap =  new Map<Id,Account>([Select id,Location_ID_5_digit__c from account where id in: accid
                                           and Location_ID__c != '']);
        return accmap;
    }
    
    public  Map<String,Account> getLocationMap(Set<String> loc) {
        Map<String,Account> accmap = new Map<String,Account>();        
        Set<Id> practiceRT = new Set<Id>();
        
        for (RecordType rt : [SELECT Id FROM RecordType 
                              WHERE SobjectType = 'Account' 
                              AND Name IN ('Schedule Assist', 'Appointment', 'DDS Practice', 'Partnership', 'Registration')]) {
                                  practiceRT.add(rt.Id);
                              }
        
        if(loc != null) {
            
            List<Account> lstA = [
                SELECT Id,Name,Location_ID_5_digit__c 
                FROM Account 
                WHERE Location_ID_5_digit__c in: loc
                AND RecordTypeId IN :practiceRT
            ];
            
            for(Account a: lstA) {
                accmap.put(a.Location_Id_5_digit__c, a);
            }
        }
        return accmap;
    }
    
    public String[] getLocationFromSubject(String subject) {                
        String[] strLocation = new String[]{};            
            if(String.isNotEmpty(subject)){
                Pattern pat = Pattern.compile('([0-9]+)');
                Matcher matcher = pat.matcher(subject);
                while (matcher.find()) {
                    strLocation.add(subject.substring(matcher.start(),matcher.end()));
                }      
            }        
        return strLocation;            
    }   
    
    public List<Case> getRedgateDupes(Set<string> rgSubject) {
        Id aceId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ACE Service').getRecordTypeId();
        return [Select Id, Subject, Createddate from case where recordtypeid = :aceId 
                and createddate = TODAY and origin = 'Redgate' and subject in :rgSubject];
    }
    
    public Boolean isRecordType(Case c,String rt) {   
        if(Schema.SObjectType.Case.getRecordTypeInfosByName().get(rt)!=null) {
            Id rtId= Schema.SObjectType.Case.getRecordTypeInfosByName().get(rt).getRecordTypeId();
            return (c.RecordTypeId == rtId);}
        else {
            return false;
        }
    }  
    
    public String addCategorySubcategoryToSubject(String subject, String cat, String subcat) {
        if(String.isNotEmpty(subject)) {
            if(!subject.startswith(cat)) 
                subject = cat + ' | ' + subcat + ' | '+subject; 
        }        
        return subject;
    }
    
    public void checkEmailIsBlockedFromCreatingCase(Map<String,Case> mapWebEmailCase){
        List<Email_Blacklist__c> lstBlockedEmails = new List<Email_Blacklist__c>();
        Case blockedCase = new Case();
        lstBlockedEmails = [Select id, email__c from Email_Blacklist__c where email__c in :mapWebEmailCase.keyset()];
        
        if(lstBlockedEmails.size() > 0){
            for(Email_Blacklist__c email: lstBlockedEmails){
                blockedCase = mapWebEmailCase.get(email.email__c);
                if(blockedCase!=null)
                    blockedCase.addError('Cannot create case with subject: ' + blockedCase.Subject + 'as the web email: ' + blockedCase.suppliedEmail + '  is blocked [debug code case3]');
            }
        }
    }
    
}