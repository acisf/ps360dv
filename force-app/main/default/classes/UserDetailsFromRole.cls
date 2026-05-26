public class UserDetailsFromRole {
    
    @InvocableMethod (label='UserDetailsFromRole')
    public static List<List<Id>> getUserDetailsFromRole(List<List<Id>> ids){
        List<Group> lstGrp = [Select Id,type, RelatedId from Group where id in :ids[0]];
        List<Group> lstChildGrp = new List<Group>();
        List<GroupMember> lstGrpMem = new List<GroupMember>();
        Set<Id> roleids = new Set<Id>();
        Set<Id> grpids = new Set<Id>();
        List<Id> uids = new List<Id>();
        
        if(lstGrp.size() > 0){           
            for(Group grp: lstGrp){
                if(grp.type.startsWith('Role'))
                    roleids.add(grp.RelatedId);
                else
                    grpids.add(grp.id);
            }
            
            if(grpids.size() > 0){
                lstGrpMem = [Select Groupid, UserorGroupId from GroupMember where groupid in :grpids];
                
                if(lstGrpMem.size() > 0){
                    grpids.clear();
                    for(GroupMember grpmem: lstGrpMem){
                        String userorgroup = Id.valueOf(grpmem.userorgroupid);
                        if(userorgroup.startsWith('00G'))
                            grpids.add(grpmem.userorgroupid);
                    }
                    
                    lstChildGrp = [Select Id,type, RelatedId from Group where id in :grpids];
                    for(Group grp: lstChildGrp){
                        if(grp.type.startsWith('Role'))
                            roleids.add(grp.RelatedId);                 
                    }
                }
            }
            
            if(roleids.size() > 0){
                for(User u: [Select id, Name from User where Userroleid in :roleids order by Name]){
                    uids.add(u.id);
                }
            }
        }
        return (new List<List<Id>>{uids});
    }

}