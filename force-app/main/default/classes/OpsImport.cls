public class OpsImport {
    public static void updateImportRecords(){
        Map<String, User> usermap = new Map<String, user>();
        Map<String, Contact> contactMap =new Map<String, Contact>();
        Map<String, Account> locationMap = new Map<String, Account>();
        Set<String> names=new set<string>();
        Set<String> locations = new Set<String>();
        
        List<ops_import__c> importData = [SELECT Id, OwnerId, LocationId__c, DFO__c, VPFO__c, Name__c, Model__c, LOM__c, DLO__c, CCO__c,
                                          VPId__c,DirectorId__c,Practice__c, LOMId__c,VPFOId__c, DFOId__c, Updated__c, PDS__c, 
                                           PDSId__c, DLOId__c, CCOId__c FROM ops_import__c];
        for  (ops_import__c importRecord : importData) {
            names.add(importRecord.VPFO__c);
            names.add(importRecord.DFO__c);
            names.add(importRecord.LOM__c);
            names.add(importRecord.PDS__c);
            names.add(importRecord.DLO__c);
            names.add(importRecord.CCO__c);
            locations.add(importRecord.LocationId__c.leftPad(5,'0'));
        }
        List<User> users = [SELECT ID,Name FROM User WHERE name IN:Names];
        List<Contact> contacts = [SELECT ID, Name FROM Contact WHERE name IN:Names AND RecordTypeId = '0121R000001QJzCQAW'];
        List<Account> accounts = [SELECT Id, Location_Id_5_digit__c FROM Account WHERE Location_Id_5_digit__c in: locations];
        
        for (User u: users){
            userMap.put(u.Name, u);
        }
        
        for( Contact c: contacts) {
            contactMap.put(c.Name,c);
        }
        
        for(Account a: accounts) {
            locationMap.put(a.Location_Id_5_digit__c,a);
        }
        
        for(ops_import__c importRecord: importData) {
            if(contactMap.get(importRecord.VPFO__c) != null) {
                importRecord.VPFOId__c = contactMap.get(importRecord.VPFO__c).id;
                
                if(userMap.containsKey(importRecord.VPFO__c)){
                     importRecord.VPId__c = userMap.get(importRecord.VPFO__c).id; 
                }
              
            }
            if(contactMap.get(importRecord.DFO__c) != null) {
                importRecord.DFOId__c = contactMap.get(importRecord.DFO__c).id;
                
              if (userMap.containsKey(importRecord.DFO__c)) {
                    importRecord.DirectorId__c = userMap.get(importRecord.DFO__c).Id;
                }
            }
            if(contactMap.get(importRecord.LOM__c) != null) {
                importRecord.LOMId__c = contactMap.get(importRecord.LOM__c).id;
            }
            if(contactmap.get(importRecord.PDS__c)!=null){
                importRecord.PDSId__c= contactmap.get(importRecord.PDS__c).id;
            }
            if(contactmap.get(importRecord.CCO__c)!=null){
                importRecord.CCOId__c= contactmap.get(importRecord.CCO__c).id;
            }
            if(contactmap.get(importRecord.DLO__c)!=null){
                importRecord.DLOId__c = contactmap.get(importRecord.DLO__c).id;
            }
            if(locationMap.get(importRecord.LocationId__c.leftPad(5,'0')) != null) {
                importRecord.Practice__c = locationMap.get(importRecord.LocationId__c.leftPad(5,'0')).Id;
            }
            
        }
        
        update importData;
    }
    
    public static void updatePracticeRecords(Integer intLimit) {
        
        Set<String> locations = new Set<String>(); 
        List<Account> lstUpdateAccounts = new List<Account>();
        Map<String ,ops_import__c> importmap = new Map<String,ops_import__c>();
        
        List<ops_import__c> importData = [SELECT Id, OwnerId, LocationId__c, DFO__c, VPFO__c, Name__c, Model__c, LOM__c, DLO__c, CCO__c,
                                          VPId__c,DirectorId__c,Practice__c, LOMId__c,VPFOId__c, DFOId__c, Updated__c, PDS__c, 
                                           PDSId__c, DLOId__c, CCOId__c FROM ops_import__c
                                          WHERE Updated__c = FALSE
                                          LIMIT :intLimit];
         
        
        for  (ops_import__c importRecord : importData) {
            locations.add(importRecord.LocationId__c.leftPad(5,'0'));
            importmap.put(importRecord.LocationId__c.leftPad(5,'0'),importRecord);
        }
        
        List<Account> accounts = [SELECT Id, VPFO__c, DFO__c, PDS__c,DLO__c,CCO__c,	LOM__c, Model__c, Location_Id_5_digit__c 
                                  FROM Account 
                                  WHERE Location_Id_5_digit__c in: locations];
        
        
        for(Account a: accounts) {
            if(importmap.containskey(a.Location_ID_5_digit__c)) {
                Ops_import__c importRecord = importmap.get(a.Location_ID_5_digit__c);
                if (importRecord.VPFOId__c != null){
                     a.VPFO__c = importRecord.VPFOId__c;
                } 
                if(importRecord.DFOId__c!=null)
                {a.DFO__c = importRecord.DFOId__c;
                }
                if(importRecord.LOMId__c!=null){
                    a.LOM__c = importRecord.LOMId__c;
                }
                if(importRecord.PDSId__c!=null){
                    a.PDS__c = importRecord.PDSId__c;
                }
                if(importrecord.CCOId__c!=null){
                    a.CCO__c = importrecord.CCOId__c;
                }
                if(importRecord.DLOId__c!=null){
                    a.DLO__c = importRecord.DLOId__c;
                }
                a.Model__c = importRecord.Model__c;
               
                importRecord.Updated__c = true;
                
          
                
                if (importRecord.DFOId__c != null) {
                    a.OwnerId = importRecord.DirectorId__c;
                } else if (importRecord.VPFOId__c != null) {
                    a.OwnerId = importRecord.VPId__c;
                }
             
                lstUpdateAccounts.add(a);
            }
        }
        
        update importData;
       
        Database.SaveResult[] updateResults = Database.update(lstUpdateAccounts, false);
        
        for (Database.SaveResult sr : updateResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Error updating Account record: ' + err.getMessage());
                }
            }
        } 
    }
}