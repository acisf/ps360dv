@IsTest
public class OpsImportTest {
    @IsTest
    static void testUpdateImportRecords() {
        // Create test data
        List<ops_import__c> importData = new List<ops_import__c>();
        List<account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        
        // Add test records to importData list
        Account a = new Account();
        a.Name = 'Test Practice';
        a.Location_Id__c = '1234';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'Doe';
        c.Email = 'johndoeopstesting1234_affordable_care_llc@example.com';
        c.AccountId = a.Id;
       /* u.Email = u.Username;
        u.alias = 'jdoe';
        u.TimeZoneSidKey = 'America/New_York';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
		u.LanguageLocaleKey = 'en_US';
		u.ProfileId = '00e36000000OlsZAAS';          
       */
        insert c;
        
        ops_import__c oi = new ops_import__c();
        oi.LocationId__c = '1234';
        oi.DFO__c = 'John Doe';
        oi.VPFO__c = 'John Doe';
        oi.Name__c = 'Test Practice';
        oi.Model__c= 'PO';
        oi.PDS__c = 'John Doe';
        oi.LOM__c = 'John Doe';
        oi.CCO__c ='John Doe';
        oi.DLO__c = 'John Doe';
        oi.Updated__c= false;
        importData.add(oi);
        insert importData;
        
        // Call the method to test
        Test.startTest();
        OpsImport.updateImportRecords();
         OpsImport.updatePracticeRecords(1);
        Test.stopTest();
        
        // Assert the expected results
        ops_import__c testoi = [SELECT Id, OwnerId, LocationId__c, DFO__c, VPFO__c, Name__c, Model__c, LOM__c, DLO__c, CCO__c,
                                          VPId__c,DirectorId__c,Practice__c, LOMId__c,VPFOId__c, DFOId__c, Updated__c, PDS__c, 
                                           PDSId__c, DLOId__c, CCOId__c FROM ops_import__c LIMIT 1];
        
        Account testaccount = [SELECT Id, VPFO__c, DFO__c, LOM__c,PDS__c,CCO__c,DLO__c, Model__c, Location_Id_5_digit__c 
					FROM Account 
					WHERE Id =: a.id 
					LIMIT 1];
        
        System.assert(oi.Updated__c = true);
        System.assert(testAccount.VPFO__c == testoi.VPFOId__c);
        
    }
    
}