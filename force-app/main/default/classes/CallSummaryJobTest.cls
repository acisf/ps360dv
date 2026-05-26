@isTest
public class CallSummaryJobTest {
 static testMethod void test_Job() {
      NVMStatsSF__NVM_Call_Summary__c call1 = new NVMStatsSF__NVM_Call_Summary__c();
        NVMStatsSF__NVM_Call_Summary__c call2 = new NVMStatsSF__NVM_Call_Summary__c();  
        
      //test data for fees/services call > new tracking object
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account a = new Account(name='Asheville - NC', recordtypeid=RecordTypeIdAcct);
        insert a;
        
        Contact c = new Contact(firstname='John',lastname='Doe',email='jdoe@example.com');
        c.accountid = a.id;
        insert c; 
     
        call1 = new NVMStatsSF__NVM_Call_Summary__c();
        call1.NVMStatsSF__CLID__c = '9198005551212';
        call1.NVMStatsSF__NVM_Service_Name__c = 'Asheville';
        call1.NVMStatsSF__Related_Contact__c = c.id;
        call1.NVMStatsSF__EndRecorded__c = true; 
        call1.NVMStatsSF__CallDisposition__c = 'Scheduled';
        call1.NVMStatsSF__CallTime__c = DateTime.newInstance(Date.today() -1,time.newInstance(11,0,0,0));
        call1.NVMStatsSF__Interaction_Type__c = 'Inbound Call';
        call1.NVMStatsSF__Agent_Talk_Time__c = 0;
        insert call1;
       

        system.debug(call1);  
     system.test.startTest();
     CallSummaryJob.run();
     system.test.stopTest();
     
         call1 =   [SELECT Id, NVMStatsSF__CallTime__c, Service_Name_Practice__c, 
                   NVMStatsSF__Related_To__c,NVMStatsSF__CallDisposition__c,Service_Practice_Match__c
                        FROM NVMStatsSF__NVM_Call_Summary__c 
                           WHERE Id =: call1.id ];
     system.debug(call1);
     system.assertEquals(1,CallSummaryJob.lstScheduled.size());
     system.assertequals(true,call1.Service_Practice_Match__c);
}
}