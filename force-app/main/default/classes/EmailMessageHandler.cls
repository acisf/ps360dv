public class EmailMessageHandler{
    
    @InvocableMethod (label='EmailMessageHandler')    
	public static void scanEmailSubject(List<id> emailMsgId){	

        List<EmailMessage> lstEmailMsg = new List<EmailMessage>();
        Set<String> locationIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        Map<Id,Case> mapCases = new Map<Id,Case>();
        List<Case> lstCases = new List<Case>();  
        List<Case> lstUpdatedCases = new List<Case>();        
        Map<String,Account> mapLocation = new Map<String,Account>();        
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        Map<EmailMessage,Set<string>> mapEmailToNewLocation = new Map<EmailMessage,Set<String>>();
	
        lstEmailMsg = getEmailList(emailMsgId);

		for(EmailMessage em: lstEmailMsg){
            String[] strLocation;
            caseIds.add(em.ParentId);
			strLocation = getLocationFromSubject(em.Subject);
            locationids = getLocationIdSet(strLocation);
            mapEmailToNewLocation.put(em,locationIds);
		}

		mapLocation = setMapLocationToAccount(locationIds);        
        dmlOpts = setAssignmentRule(dmlOpts);
        
        if(caseIds.size() > 0){
            lstCases = getCasesFromEmailMessage(caseIds);            
            if(lstCases.size() > 0){
                mapCases = setMapWithCases(lstCases);
            }
        }        

        for(EmailMessage em: lstEmailMsg){ 
            set<String> newLocations = new set<string>();
            
            if( mapEmailToNewLocation.get(em) != null) {
                newLocations = mapEmailToNewLocation.get(em);
            }            
            lstUpdatedCases.add(setCasePracticeAndOwner(em,newLocations,mapCases,mapLocation,dmlOpts));                    
  		}
        updateCases(lstUpdatedCases,dmlOpts);                	
	}

    public static List<EmailMessage> getEmailList(List<id> emailMsgId) {
        List<EmailMessage> lstEM = new List<EmailMessage>();
        lstEM = [Select id, Subject, ParentId from EmailMessage where id in :emailMsgId
                                         and incoming = true];
        return lstEM;
    }

    public static set<String> getLocationIdSet(string[] locationid) {
        Set<string> locationids = new Set<String>();
        for(string loc: locationid) {
            if(String.isNotBlank(loc)) {   
                if(loc.length() < 5)
                    loc = '0' + loc;
                    locationIds.add(loc);
            }	    
        }
        return locationids;
    }

	public static String[] getLocationFromSubject(String subject) {                
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
	public static Map<String,Account> setMapLocationToAccount(Set<String> loc) {
        Map<String,Account> accmap = new Map<String,Account>();
        if(loc != null) {
            List<Account> lstA = [Select id,name,Location_ID_5_digit__c from account where Location_ID_5_digit__c in: loc
                                 and Location_ID_5_digit__c != '0'];
            for(Account a: lstA) {
                accmap.put(a.Location_Id_5_digit__c, a);
            }
        }
        return accmap;
    }

    public static List<Case> getCasesFromEmailMessage(Set<Id> caseIds){
        List<Case> lstCases = new List<Case>();
        lstCases = [Select id, AccountId, Practice_Location_ID__c, Location_found__c from Case where id in :caseIds];
        return lstCases;
    }

    public static Map<Id,Case> setMapWithCases(List<Case> lstCases){
        Map<Id,Case> mapCases = new Map<Id,Case>();
        for(Case c: lstCases)
            mapCases.put(c.Id,c);
        return mapCases;
    }
   
    public static Database.DMLOptions setAssignmentRule(Database.DMLOptions dmlOpts){
        AssignmentRule AR = new AssignmentRule();
        AR = [select id,name from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        dmlOpts.assignmentRuleHeader.assignmentRuleId = AR.id;
        return dmlOpts;
    }

    public static Case setCasePracticeAndOwner(EmailMessage em,Set<String> newLocations,Map<Id,Case> mapCases,Map<String,Account> mapLocation,Database.DMLOptions dmlOpts){
        Case updatedCase = new Case();
        for(string loc:newLocations) {                
            if(mapLocation.size() > 0 && mapLocation.get(loc) != null) {
                mapCases.get(em.ParentId).AccountId = mapLocation.get(loc).Id;
                mapCases.get(em.ParentId).Location_found__c = true;
                mapCases.get(em.ParentId).setOptions(dmlOpts);
                updatedCase = mapCases.get(em.ParentId);
            }
        } 
        return updatedCase; 
    }

    public static void updateCases(List<Case> lstCases, Database.DMLOptions dmlOpts){
        if(lstCases.size() > 0){
            try {                
                Database.update(lstCases,dmlOpts);
            } catch (Exception e) {
                System.System.debug('Exception during updating case account from email reply: ' + e.getMessage());
            }
        }   
    }
}