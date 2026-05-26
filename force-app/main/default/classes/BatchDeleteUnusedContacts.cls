public class BatchDeleteUnusedContacts implements Database.Batchable<Sobject>{
        
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select id,name,email,description, fb_lead_id__c from contact ' + 
                       'where createddate < Last_N_Days: 30 ' +
                       'and contact.recordtype.name = \'Patient\' order by name';
        return Database.getQueryLocator(query);        
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        List<Contact> lstCon = (List<Contact>) scope;
        List<Contact> lstDeleteCon = new List<Contact>();
        Map<Id,Contact> mapCon = new Map<Id,Contact>();		
		Set<Id> conIds = new Set<ID>();
		Integer count;
		Id contactId;
        
        if(lstCon.size() > 0){
            for(Contact con: lstCon){
                //Store Practice review contact ids
                if(con.description == 'Practice Review email'){                    
                    conIds.add(con.id);
                }
                //Store Facebook contact ids
                else if(con.fb_lead_id__c != NULL && con.fb_lead_id__c != ''){                    
                    conIds.add(con.id);
                }
            }
        }        
        
        if(conIds.size() > 0){
            //Get the total count of tasks associated with each contact
            List<AggregateResult> totalTasks = [Select count(id) tasks, whoId conId from Task 
                                                where whoid in :conIds
                                                group by whoId];
            
            List<AggregateResult> totalCases = [Select count(id) cases, contactId contId from Case 
                                                where contactId in :conIds
                                                group by contactId];
            
            for(AggregateResult ar:totalTasks){
                count = (Integer)ar.get('tasks');
                contactId = (Id)ar.get('conId');
                If(count > 0){
                    //Remove the contact id if there are tasks associated with that contact
                    conIds.remove(contactId);                            
                }
            }
            
            for(AggregateResult ar:totalCases){
                count = (Integer)ar.get('cases');
                contactId = (Id)ar.get('contId');
                If(count > 0){
                    //Remove the contact id if there are tasks associated with that contact
                    conIds.remove(contactId);                            
                }
            }
            
            for(Contact con: lstCon){
                if(conIds.contains(con.Id)){
                    //Create a list of contacts with no tasks or cases for deletion
                    lstDeleteCon.add(con);
                }
            }
        }
        try{
            if(lstDeleteCon.size() > 0){
                delete lstDeleteCon;
                DataBase.emptyRecycleBin(lstDeleteCon);
            }
        }
        Catch(Exception e){
            System.debug('Error during deleting FB and PR contacts with no tasks: ' + e.getMessage());
        }
    }
    public void finish(Database.BatchableContext bc){
    }

}