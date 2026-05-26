public class CaseOwnershipChange {
    
    @InvocableMethod(label = 'Case Owner Changed')
    public static void caseOwnerChanged(List<id> caseid){
        	List<Case> cases = [Select Id, OwnerId, Queue_Name__c from case where id in :caseid];
        	List<Case> caseupd = new List<Case>();
            Set<Id> owner_id = new Set<Id>();
            Set<ID> user1_id = new Set<ID>();        
            Map<Id,String> case_queue_name = new Map<Id,String>();
            Map<Id,String> q_name = new Map<Id,String>();
            Map<Id,String> u_name = new Map<Id,String>();
        	String owner;            
           
            for(Case c: cases){                    
                owner = c.OwnerId;
                if(owner.StartsWith('00G')){		//Case owner is a queue
                    owner_id.add(c.OwnerId);
                }
                else{								//Case owner is user
                    if(c.Queue_Name__c == null)		//If case is created manually without assignment rules
                        user1_id.add(c.OwnerId);
                    else                	
                        case_queue_name.put(c.OwnerId, c.Queue_Name__c);    //If case is created via portal/email, store the case owner and existing queue            
                }
            }          
                              
            
            if(owner_id.size() > 0){   
                //Find the queue name for Case owner = queue 
                for(Group g: [Select Id, Name from Group where id in :owner_id and type='Queue'])           
                    q_name.put(g.Id, g.Name);
            }
            else if(user1_id.size() > 0){
                //Find the primary queue of the user from User object if case owner = user and case is created manually
                For(User u: [Select Id, Primary_queue__c from user where Id in: user1_id])		
                    u_name.put(u.Id, u.Primary_queue__c);
            }
            else if(case_queue_name.size() > 0){	//Case owner = user and case is created via portal/email
                
                //Check if the user belongs to the queue. If the user is member of queue, no action is required
                List<Groupmember> gm = [Select Id, UserOrGroupId, Group.Name from GroupMember where UserorGroupId in :case_queue_name.keyset() and Group.Name Like :case_queue_name.values()];
                
                if(gm.size() == 0){			
                    //If user is not member of queue, then get the user's primary queue from User object
                    For(User u: [Select Id, Primary_queue__c from user where Id in: case_queue_name.keyset()])
                        u_name.put(u.Id, u.Primary_queue__c);
                }
            }
            
            For(Case c: cases){
                // Case owner = queue and Queue name is different from existing queue or null
                if(q_name.get(c.OwnerID)!=null && c.Queue_Name__c != q_name.get(c.OwnerId)){                
                    c.Queue_Name__c = q_name.get(c.OwnerId);                    
                    caseupd.add(c);
                }   
                // Case owner = user and Queue name is different from User's queue
                else if(u_name.get(c.OwnerId) != null && c.Queue_Name__c != u_name.get(c.OwnerId)){
                    c.Queue_Name__c = u_name.get(c.OwnerId);                    
                    caseupd.add(c);
                }
            }          
           
                update caseupd; 
      }         

}