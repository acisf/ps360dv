@isTest
public class CnaJobTest {
    
    static testMethod void testCNA_Job() {
                
        NVMStatsSF__NVM_Call_Summary__c fscall = new NVMStatsSF__NVM_Call_Summary__c();
        NVMStatsSF__NVM_Call_Summary__c schedulecall = new NVMStatsSF__NVM_Call_Summary__c();  
        CNA_Tracking__c t;
        
        //test data for fees/services call > new tracking object
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account a = new Account(name='Abilene - Texas',cna_emailoptin__c=true, cna_robocalloptin__c=true,
                                cna_directmailoptin__c=true, recordtypeid=RecordTypeIdAcct);
        insert a;
        
        Contact c = new Contact(firstname='John',lastname='Doe',email='jdoe@example.com');
        c.accountid = a.id;
        insert c; 
        
        fscall = new NVMStatsSF__NVM_Call_Summary__c();
        fscall.NVMStatsSF__Related_Account__c = a.id;
        fscall.NVMStatsSF__Related_Contact__c = c.id;
        fscall.NVMStatsSF__CallTime__c = DateTime.newInstance(Date.today() -1,time.newInstance(11,0,0,0));
        fscall.NVMStatsSF__Interaction_Type__c = 'Inbound Call';
        fscall.NVMStatsSF__CallDisposition__c = 'Fees/Services';
        insert fscall;
        
        //test data for existing cna_tracking > schedule call > appointed
        RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        a = new Account(name='Abilene - Texas',cna_emailoptin__c=true, cna_robocalloptin__c=true,
                        cna_directmailoptin__c=true, recordtypeid=RecordTypeIdAcct);
        insert a;
        
        c = new Contact(firstname='John',lastname='Doe',email='jdoe@example.com');
        c.accountid = a.id;
        insert c;  
        
        fscall = new NVMStatsSF__NVM_Call_Summary__c();
        fscall.NVMStatsSF__Related_Account__c = a.id;
        fscall.NVMStatsSF__Related_Contact__c = c.id;
        fscall.NVMStatsSF__CallTime__c = DateTime.newInstance(Date.today() -10,time.newInstance(11,0,0,0));
        fscall.NVMStatsSF__Interaction_Type__c = 'Inbound Call';
        fscall.NVMStatsSF__CallDisposition__c = 'Fees/Services';
        insert fscall;
        
        t= new CNA_Tracking__c();
        t.CNA_Contact__c = c.id;
        t.CNA_Initial_Call__c = fscall.id;
        t.CNA_InitialCallTime__c = fscall.NVMStatsSF__CallTime__c;
        t.CNA_Status__c = 'Email';
        insert t;
        
        fscall = new NVMStatsSF__NVM_Call_Summary__c();
        fscall.NVMStatsSF__Related_Account__c = a.id;
        fscall.NVMStatsSF__Related_Contact__c = c.id;
        fscall.NVMStatsSF__CallTime__c = DateTime.newInstance(Date.today() -1,time.newInstance(11,0,0,0));
        fscall.NVMStatsSF__Interaction_Type__c = 'Inbound Call';
        fscall.NVMStatsSF__CallDisposition__c = 'Scheduled';
        insert fscall; 
        
        
        //test data for Email > Robocall
        Account acct3 = new Account(name='Richmond - Virginia',recordtypeid=RecordTypeIdAcct);      
        Contact ct3 = new Contact(firstname='Joe',lastname='SMith',email='jsmith@example.com');
        insert acct3;
        ct3.AccountId = acct3.id;
        insert ct3; 
        
        t= new CNA_Tracking__c();
        t.CNA_Contact__c = ct3.id; 
        t.CNA_InitialCallTime__c = DateTime.newInstance(Date.today() -1,time.newInstance(11,0,0,0));
        t.CNA_Status__c = 'Email';
        insert t;
        ct3.HasOptedOutOfEmail = true;
        update ct3;
        
          //test data for Direct Mail after 30 days
        Account acct2 = new Account(name='Danville - Virginia',recordtypeid=RecordTypeIdAcct);    
        Contact ct2 = new Contact(firstname='Jane',lastname='Doe',email='janedoe@example.com');
        insert acct2;
        ct2.AccountId = acct2.id;
        insert ct2; 
        
        t= new CNA_Tracking__c();
        t.CNA_Contact__c = ct2.id; 
        t.CNA_InitialCallTime__c = DateTime.newInstance(Date.today() -31,time.newInstance(11,0,0,0));
        t.CNA_Status__c = 'Email';
        insert t;
        
        List<integer> lstNumbers =  new List<Integer>{0,1,2,3,4};      
        
        Test.startTest(); 
        CnaJob.insertCNATracking();     
        CnaJob.updateScheduled();                 
        CnaJob.updateEmailOptOuts();      
        CnaJob.updateRobocallOptOuts(); 
        lstNumbers = CnaJob.randomize(lstNumbers);
        System.debug('Random Numbers');
        System.debug(lstNumbers);
        System.debug('Subset');
        System.debug(CnaJob.getSubset(lstNumbers,2));
        Test.stopTest();
        
        System.assertEquals(1,CnaJob.lstNewTracking.size());
        System.assertEquals(1,CnaJob.lstAppointed.size());          
        System.assertEquals(1,CnaJob.lstDoNotEmail.size());    
        //System.assertEquals(5,lstNumbers.size());
        System.assertEquals(2,CnaJob.getSubSet(lstNumbers,2).size());
    }    
    
    
}