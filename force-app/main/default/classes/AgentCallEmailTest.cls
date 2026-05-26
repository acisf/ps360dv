@isTest
public class AgentCallEmailTest {
    
    static testMethod void test() {
 		NVMStatsSF__NVM_Call_Summary__c fscall = new NVMStatsSF__NVM_Call_Summary__c();
        NVMStatsSF__NVM_Agent_Summary__c agentsummary = new NVMStatsSF__NVM_Agent_Summary__c();  
        CNA_Tracking__c t;
        
        //test data - agent summary
        agentsummary = new NVMStatsSF__NVM_Agent_Summary__c();  
        agentsummary.Unique_Prospect_Fees_Services_Calls__c = 0;
        agentsummary.NVMStatsSF__Agent__c = UserInfo.getUserId();
        agentsummary.NVMStatsSF__dateAgentId__c = '1';
        agentsummary.NVMStatsSF__Date__c = Date.today() - 1;
        insert agentsummary;
        
        //test data - fees/services
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account a = new Account(name='Abilene - Texas',cna_emailoptin__c=true, cna_robocalloptin__c=true,
                                cna_directmailoptin__c=true, recordtypeid=RecordTypeIdAcct);
        insert a;
        
        Contact c = new Contact(firstname='John',lastname='Doe',email='jdoe@example.com');
        c.accountid = a.id;
        insert c; 
        
        fscall = new NVMStatsSF__NVM_Call_Summary__c();
        fscall.NVMStatsSF__Last_Agent_Summary__c = agentsummary.id;
        fscall.NVMStatsSF__Agent__c = UserInfo.getuserid();
        fscall.NVMStatsSF__Related_Account__c = a.id;
        fscall.NVMStatsSF__Related_Contact__c = c.id;
        fscall.NVMStatsSF__CallTime__c = DateTime.newInstance(Date.today() -1,time.newInstance(11,0,0,0));
        fscall.NVMStatsSF__Interaction_Type__c = 'Inbound Call';
        fscall.NVMStatsSF__CallDisposition__c = 'Fees/Services';
        insert fscall;
        
        test.startTest(); 
        
		AgentCallEMail.run();
        
        agentsummary = [select id,Unique_Prospect_Fees_Services_Calls__c,NVMStatsSF__Agent__c,Number_of_Fees_Services_Calls__c from NVMStatsSF__NVM_Agent_Summary__c];
        system.assertequals(UserInfo.getUserId(),agentsummary.NVMStatsSF__Agent__c);
         system.assertequals(1,agentsummary.Unique_Prospect_Fees_Services_Calls__c);
         system.assertequals(1,agentsummary.Number_of_Fees_Services_Calls__c);
          test.stopTest();
        
    }
}