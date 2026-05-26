public class UpdateChildCases {
    
    @InvocableMethod(label='Update child case status')
    public static void updateChildCasesStatus(List<Id> parentId){
        //Get the related child cases
        List<Case> parentCase = [Select Id, Status from Case where id in :parentId ];
        List<Case> childcases = [select id, status, parentid from case where parentid in :parentId];
        Map<Id,String> p_status = new Map<Id,String>();
        
        for(Case p_c: parentCase)
            p_status.put(p_c.id,p_c.status);        
        
        if(childcases.size() > 0){
        //Update the child case's status
            for(Case c: childcases)  {                  
                c.Status = p_status.get(c.ParentId);
                System.debug('Child Case ' + c.status);
            }
        update childcases;
        }
    }

}