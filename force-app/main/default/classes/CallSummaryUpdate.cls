global class CallSummaryUpdate implements Database.Batchable<sObject>, Database.Stateful {
    
    global Set<id> tskids;         
    global Map<Id,Task> tskList;
    global List<Sobject> lstSObject;
    global String tskSubcategory;
    global String tskReasonForNotScheduling;
    global String tskInsurance;
    
    global CallSummaryUpdate(List<Sobject> lstObj){
        lstSObject = lstObj;   
    }
    
    global Iterable<Sobject> start(Database.BatchableContext bc){        
        return lstSObject;
    }
    
    global void execute(Database.BatchableContext bc, List<Sobject> lstObj){
        tskids = new Set<Id>();
        List<NVMStatsSF__NVM_Call_Summary__c> lstCS = new List<NVMStatsSF__NVM_Call_Summary__c>();
        NVMStatsSF__NVM_Call_Summary__c cs = new NVMStatsSF__NVM_Call_Summary__c();
        for(Sobject so: lstObj) {
            cs = (NVMStatsSF__NVM_Call_Summary__c)so;
            lstCS.add(cs);
        }
        retrieveTaskIdsFromCallSumary(lstCS);
        retrieveSubcategoryFromRelatedTasks();
        assignTaskSubcategoryToCallSummaryList(lstCS);
        updateCallSummaryList(lstCS);        
    }
    
    global void retrieveTaskIdsFromCallSumary(List<NVMStatsSF__NVM_Call_Summary__c> nvm_summary){
         for(NVMStatsSF__NVM_Call_Summary__c nvm : nvm_summary){    
            tskids.add(nvm.NVMStatsSF__TaskID__c);
            System.debug('Task Id ' + nvm.NVMStatsSF__TaskID__c);
        }
    }
    
    global void retrieveSubcategoryFromRelatedTasks(){        
        tskList = new Map<Id,Task>();
        if(tskids.size() > 0){            
            for(Task t: [Select id,Answered_Outcome__c, Reason_for_Not_Scheduling__c, Insurance__c from Task where id in :tskids  ALL ROWS]){
                tskList.put(t.id,t);
            }
        }        
    }
    global void assignTaskSubcategoryToCallSummaryList(List<NVMStatsSF__NVM_Call_Summary__c> nvm_summary){        
        if(tskList.size() > 0){
            for(NVMStatsSF__NVM_Call_Summary__c nvm : nvm_summary){               
                if(tskList.get(nvm.NVMStatsSF__TaskID__c) != null){
                    
                    tskSubcategory = tskList.get(nvm.NVMStatsSF__TaskID__c).Answered_Outcome__c;
                    tskReasonForNotScheduling = tskList.get(nvm.NVMStatsSF__TaskID__c).Reason_for_Not_Scheduling__c;
                    tskInsurance = tskList.get(nvm.NVMStatsSF__TaskID__c).Insurance__c;
                    
                    if(tskSubcategory != null && nvm.Call_Result_Subcategory__c != tskSubcategory){
                        nvm.Call_Result_Subcategory__c = tskSubcategory;
                        System.debug('Subcategory ' + nvm.Call_Result_Subcategory__c);
                    }
                    
                    if(tskReasonForNotScheduling != null && nvm.Reason_for_Not_Scheduling__c != tskReasonForNotScheduling){
                        nvm.Reason_for_Not_Scheduling__c = tskReasonForNotScheduling;
                        System.debug('Reason for not scheduling' + nvm.Reason_for_Not_Scheduling__c);
                    }
                    
                    if(tskInsurance != null && nvm.Insurance_Plan__c != tskInsurance){
                        nvm.Insurance_Plan__c = tskInsurance;
                        System.debug('Insurance ' + nvm.Insurance_Plan__c);
                    }
                } 
            }
        }        
    }
    
    global void updateCallSummaryList(List<NVMStatsSF__NVM_Call_Summary__c> nvm_summary){
        try{
            Database.SaveResult[] results = Database.update(nvm_summary,false);              
            for(Database.SaveResult result: results){
                if(!result.isSuccess()){
                    for(Database.Error error: result.getErrors()){
                        System.debug('Error Status: ' + error.getStatusCode() +': Error fields: ' + error.getFields());
                    }
                }
            }
        }
        catch(Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
    
}