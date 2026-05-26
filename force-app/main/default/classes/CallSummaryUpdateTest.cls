@istest
public class CallSummaryUpdateTest {
@isTest
    public static void testNVMCallSummary(){
        Integer i;
        List<id> nvm_id = new List<id>();
        
        Account acc = new Account(Name='Test Practice');
        insert acc;
        Contact c = new Contact(FirstName='John',LastName='Test',AccountId=acc.id);
        Insert c;
        List<Task> tlist = new List<Task>();
        List<NVMStatsSF__NVM_Call_Summary__c> nvmlist = new List<NVMStatsSF__NVM_Call_Summary__c>();
        
        /* Task with subcategory*/
        for(i=1 ; i<=496 ; i++){
            Task t = new Task();
            t.WhoId = c.id;
            t.NVM_Call_Result__c = 'Fees/Services';
            t.Answered_Outcome__c = 'New Denture';
            t.Status = 'Completed';
            t.Priority = 'Normal';
            t.Subject = 'Inbound call from ' + i;
            tlist.add(t);
        }
        
        /* Fees/Services Task without subcategory but having 'Reason for not scheduling'*/
        Task t_nosubcategory = new Task();
        t_nosubcategory.WhoId = c.id;
        t_nosubcategory.NVM_Call_Result__c = 'Fees/Services'; 
        t_nosubcategory.Reason_for_Not_Scheduling__c = 'Practice doesn\'t take caller\'s insurance';
        t_nosubcategory.Insurance__c = 'Aetna';
        t_nosubcategory.Status = 'Completed';
        t_nosubcategory.Priority = 'Normal';
        t_nosubcategory.Subject = 'Inbound call from ' + i;
        tlist.add(t_nosubcategory);
        
        /* Task with call result != Fees/Services*/
        Task t_confirmed = new Task();
        t_confirmed.WhoId = c.id;
        t_confirmed.NVM_Call_Result__c = 'Confirmed';      
        t_confirmed.Status = 'Completed';
        t_confirmed.Priority = 'Normal';
        t_confirmed.Subject = 'Inbound call from Confirmed call';
        tlist.add(t_confirmed);         
        
         /* Scheduled Task with subcategory */
        Task t_scheduled = new Task();
        t_scheduled.WhoId = c.id;
        t_scheduled.NVM_Call_Result__c = 'Scheduled'; 
        t_scheduled.Answered_Outcome__c = 'New Denture';
        t_scheduled.Status = 'Completed';
        t_scheduled.Priority = 'Normal';
        t_scheduled.Subject = 'Inbound call from ' + i;
        tlist.add(t_scheduled);
        insert tlist;
        
        /*Create call summaries with tasks having subcategory*/
        for(i=1; i<=498 ; i++){
            NVMStatsSF__NVM_Call_Summary__c nvm = new NVMStatsSF__NVM_Call_Summary__c();
            nvm.NVMStatsSF__Interaction_Type__c = 'Inbound Call';
            nvm.NVMStatsSF__TaskExists__c = true;
            nvm.NVMStatsSF__CallTime__c = Datetime.now();
            nvm.NVMStatsSF__TaskID__c = tlist[i-1].id;
            nvm.NVMStatsSF__CallDisposition__c = 'Fees/Services';
            nvm.NVMStatsSF__Related_Contact__c = c.id;
            nvmlist.add(nvm);            
        }
        
        NVMStatsSF__NVM_Call_Summary__c nvm_scheduled = new NVMStatsSF__NVM_Call_Summary__c();
        nvm_scheduled.NVMStatsSF__Interaction_Type__c = 'Inbound Call';
        nvm_scheduled.NVMStatsSF__TaskExists__c = true;
        nvm_scheduled.NVMStatsSF__CallTime__c = Datetime.now();
        nvm_scheduled.NVMStatsSF__TaskID__c = t_scheduled.id;
        nvm_scheduled.NVMStatsSF__CallDisposition__c = 'Scheduled';
        nvm_scheduled.NVMStatsSF__Related_Contact__c = c.id;
        nvmlist.add(nvm_scheduled); 
        
        insert nvmlist;   
               
        Test.startTest();       
        CallSummaryUpdate nvm = new CallSummaryUpdate(nvmlist);
        Id jobid = Database.executeBatch(nvm,500);
        Test.stopTest();
        
        NVMStatsSF__NVM_Call_Summary__c nvm1 = [Select Id,Call_Result_Subcategory__c from NVMStatsSF__NVM_Call_Summary__c where NVMStatsSF__TaskID__c = :tlist[0].Id limit 1];
        NVMStatsSF__NVM_Call_Summary__c nvm2 = [Select Id,Call_Result_Subcategory__c from NVMStatsSF__NVM_Call_Summary__c where NVMStatsSF__TaskID__c = :t_confirmed.Id limit 1];
        NVMStatsSF__NVM_Call_Summary__c nvm3 = [Select Id,Call_Result_Subcategory__c,Reason_for_not_scheduling__c, Insurance_Plan__c
                                                from NVMStatsSF__NVM_Call_Summary__c where NVMStatsSF__TaskID__c = :t_nosubcategory.Id limit 1];
        NVMStatsSF__NVM_Call_Summary__c nvm4 = [Select Id,Call_Result_Subcategory__c,Reason_for_not_scheduling__c
                                                from NVMStatsSF__NVM_Call_Summary__c where NVMStatsSF__TaskID__c = :t_scheduled.Id limit 1];
        
        System.assertEquals(nvm1.Call_Result_Subcategory__c, tlist[0].Answered_Outcome__c); 
        System.assert(nvm2.Call_Result_Subcategory__c == null);      
        System.assert(nvm3.Call_Result_Subcategory__c == null);  
        System.assertEquals(nvm3.Reason_for_not_scheduling__c, t_nosubcategory.Reason_for_Not_Scheduling__c);
        System.assertEquals(nvm3.Insurance_Plan__c, t_nosubcategory.Insurance__c);
        System.assertEquals(nvm4.Call_Result_Subcategory__c, t_scheduled.Answered_Outcome__c); 
    }
}