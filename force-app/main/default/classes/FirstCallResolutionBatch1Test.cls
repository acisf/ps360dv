@isTest
public class FirstCallResolutionBatch1Test {

    @isTest
    static void testBatchExecution() {
        // Test data setup
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'jdoe@example.com', AccountId = testAccount.Id);
        insert testContact;

        // Create test Customer_Inquiry__c record for CLID 18005551213
        Customer_Inquiry__c existingInquiry = new Customer_Inquiry__c(
            CLID__c = '18005551213',
            Last_Call_DateTime__c = Datetime.now().addDays(-2), // Set last call time to 2 days ago
            Call_Count__c = 1, // Set call count to 1
            Closed__c = false
        );
        insert existingInquiry;

        // Create test NVMStatsSF__NVM_Call_Summary__c records
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = new List<NVMStatsSF__NVM_Call_Summary__c>();
        
        // Create 2 call summaries with the same CLID
        for (Integer i = 0; i < 2; i++) {
            NVMStatsSF__NVM_Call_Summary__c summary = new NVMStatsSF__NVM_Call_Summary__c(
                NVMStatsSF__CLID__c = '18005551212',
                NVMStatsSF__Related_Account__c = testAccount.Id,
                NVMStatsSF__Related_Contact__c = testContact.Id,
                NVMStatsSF__Date__c = Date.today(),
                NVMStatsSF__CallTime__c = DateTime.newInstance(Date.today().addDays(-1), Time.newInstance(11, i, 0, 0)),
                NVMStatsSF__Interaction_Type__c = 'Inbound Call',
                NVMStatsSF__CallDisposition__c = 'Fees/Services',
                NVMStatsSF__Queue_Name__c = 'Schedule Assist'
            );
            callSummaries.add(summary);
        }
        
        // Create 1 call summary for one CLID
        NVMStatsSF__NVM_Call_Summary__c repeatSummary = new NVMStatsSF__NVM_Call_Summary__c(
            NVMStatsSF__CLID__c = '18005551213', // Different CLID
            NVMStatsSF__Related_Account__c = testAccount.Id,
            NVMStatsSF__Related_Contact__c = testContact.Id,
            NVMStatsSF__Date__c = Date.today(),
            NVMStatsSF__CallTime__c = DateTime.newInstance(Date.today().addDays(-1), Time.newInstance(11, 0, 0, 0)), 
            NVMStatsSF__Interaction_Type__c = 'Inbound Call',
            NVMStatsSF__CallDisposition__c = 'Fees/Services',
            NVMStatsSF__Queue_Name__c = 'Schedule Assist'
        );
        callSummaries.add(repeatSummary);
        
        // Insert test data
        insert callSummaries;
        
        // Start the batch
        Test.startTest();
        DateTime callEnd = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day(), 0,0,0);
        FirstCallResolutionBatch1 batch = new FirstCallResolutionBatch1(callEnd);
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the results
        List<Customer_Inquiry__c> updatedInquiries = [SELECT Id, CLID__c, Call_Count__c
                                                      FROM Customer_Inquiry__c
                                                      WHERE CLID__c IN ('18005551212', '18005551213')];
        System.assertEquals(2, updatedInquiries.size(), 'Expected two Customer Inquiry records');
        for (Customer_Inquiry__c inquiry : updatedInquiries) {
            if (inquiry.CLID__c == '18005551212') {
                System.assertEquals(2, inquiry.Call_Count__c, 'Expected Call_Count__c to be 2 for CLID 18005551212');
            } else if (inquiry.CLID__c == '18005551213') {
                System.assertEquals(2, inquiry.Call_Count__c, 'Expected Call_Count__c to be 2 for CLID 18005551213');
            }
        }
    }
}