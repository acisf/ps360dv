@IsTest
private class BackfillFirstCallSummary2026_Test {

    @IsTest
    static void testBackfillFirstCallSummary() {
        // ---------------------------
        // Step 1: Create test data
        // ---------------------------
        
        // Account & Contact
        Account acct = new Account(Name = 'Test Clinic', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId());
        insert acct;
        
        Contact cont = new Contact(FirstName='Jane', LastName='Smith', Email='jsmith@example.com', AccountId=acct.Id);
        insert cont;
        
        // Customer Inquiries created in 2026
        Customer_Inquiry__c ci1 = new Customer_Inquiry__c(
            CLID__c = 'CLID001',
            Customer__c = cont.Id,
            First_Call_DateTime__c = null,
            Last_Call_DateTime__c = null,
            Call_Count__c = 0
        );
        
        Customer_Inquiry__c ci2 = new Customer_Inquiry__c(
            CLID__c = 'CLID002',
            Customer__c = cont.Id,
            First_Call_DateTime__c = null,
            Last_Call_DateTime__c = null,
            Call_Count__c = 0
        );
        insert new List<Customer_Inquiry__c>{ci1, ci2};
        
        // ---------------------------
        // Step 2: Create call summaries
        // ---------------------------
        // ci1 has two calls; ci2 has one call
        List<NVMStatsSF__NVM_Call_Summary__c> calls = new List<NVMStatsSF__NVM_Call_Summary__c>();
        
        calls.add(new NVMStatsSF__NVM_Call_Summary__c(
            NVMStatsSF__Related_Account__c = acct.Id,
            NVMStatsSF__Related_Contact__c = cont.Id,
            NVMStatsSF__CallTime__c = DateTime.newInstance(2026,1,5,9,0,0),
            Customer_Inquiry__c = ci1.Id,
            NVMStatsSF__Interaction_Type__c = 'Inbound Call'
        ));
        
        calls.add(new NVMStatsSF__NVM_Call_Summary__c(
            NVMStatsSF__Related_Account__c = acct.Id,
            NVMStatsSF__Related_Contact__c = cont.Id,
            NVMStatsSF__CallTime__c = DateTime.newInstance(2026,1,6,10,0,0),
            Customer_Inquiry__c = ci1.Id,
            NVMStatsSF__Interaction_Type__c = 'Inbound Call'
        ));
        
        calls.add(new NVMStatsSF__NVM_Call_Summary__c(
            NVMStatsSF__Related_Account__c = acct.Id,
            NVMStatsSF__Related_Contact__c = cont.Id,
            NVMStatsSF__CallTime__c = DateTime.newInstance(2026,1,7,11,0,0),
            Customer_Inquiry__c = ci2.Id,
            NVMStatsSF__Interaction_Type__c = 'Inbound Call'
        ));
        
        insert calls;
        
        // ---------------------------
        // Step 3: Run the batch
        // ---------------------------
        Test.startTest();
        BackfillFirstCallSummary2026 batch = new BackfillFirstCallSummary2026();
        Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // ---------------------------
        // Step 4: Verify results
        // ---------------------------
        ci1 = [SELECT Id, First_Call_Summary__c FROM Customer_Inquiry__c WHERE Id = :ci1.Id];
        ci2 = [SELECT Id, First_Call_Summary__c FROM Customer_Inquiry__c WHERE Id = :ci2.Id];
        
        System.assertNotEquals(null, ci1.First_Call_Summary__c, 'First call summary should be set for ci1');
        System.assertNotEquals(null, ci2.First_Call_Summary__c, 'First call summary should be set for ci2');
        
        // Verify that the earliest call is picked for ci1
        NVMStatsSF__NVM_Call_Summary__c firstCallCi1 = [SELECT Id, NVMStatsSF__CallTime__c FROM NVMStatsSF__NVM_Call_Summary__c WHERE Id = :ci1.First_Call_Summary__c];
        System.assertEquals(DateTime.newInstance(2026,1,5,9,0,0), firstCallCi1.NVMStatsSF__CallTime__c, 'Earliest call should be picked for ci1');
        
        // Verify ci2
        NVMStatsSF__NVM_Call_Summary__c firstCallCi2 = [SELECT Id, NVMStatsSF__CallTime__c FROM NVMStatsSF__NVM_Call_Summary__c WHERE Id = :ci2.First_Call_Summary__c];
        System.assertEquals(DateTime.newInstance(2026,1,7,11,0,0), firstCallCi2.NVMStatsSF__CallTime__c, 'Earliest call should be picked for ci2');
    }
}