@isTest
public class BatchPCSTest {

    @testSetup
    static void setupTestData() {
        // Create Account for test
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account a = new Account(name = 'Abilene - Texas', cna_emailoptin__c = true, 
                                cna_robocalloptin__c = true, cna_directmailoptin__c = true, 
                                recordtypeid = RecordTypeIdAcct);
        insert a;

        // Create Contact for test
        Contact c = new Contact(firstname = 'John', lastname = 'Doe', email = 'jdoe@example.com', accountid = a.id);
        insert c;

        // Create Call Summary record for test
        NVMStatsSF__NVM_Call_Summary__c call = new NVMStatsSF__NVM_Call_Summary__c();
        call.NVMStatsSF__Related_Account__c = a.id;
        call.NVMStatsSF__Related_Contact__c = c.id;
        call.NVMStatsSF__CallTime__c = DateTime.newInstance(Date.today() - 1, time.newInstance(11, 0, 0, 0));
        call.NVMStatsSF__Interaction_Type__c = 'Inbound Call';
        call.NVMStatsSF__CallDisposition__c = 'Fees/Services';
        call.NVMStatsSF__CallGuid__c = 'TestCallGuid001';
        insert call;

        // Create PCS records for test (related to the call summary)
        NVM_PCS__c pcsRecord = new NVM_PCS__c();
        pcsRecord.Call_Object_Identifier__c = 'TestCallGuid001';
        insert pcsRecord;
    }

    @isTest
    static void testBatchPCS() {
        // Start a test context
        Test.startTest();

        // Execute the batch job
        BatchPCS batchJob = new BatchPCS();
        Database.executeBatch(batchJob);

        // End the test context
        Test.stopTest();

        // Assert that the PCS record was updated with the correct Call Summary Id
        NVM_PCS__c updatedPCS = [SELECT Id, Vonage_Call_Summary__c FROM NVM_PCS__c WHERE Call_Object_Identifier__c = 'TestCallGuid001' LIMIT 1];
        NVMStatsSF__NVM_Call_Summary__c expectedCallSummary = [SELECT Id FROM NVMStatsSF__NVM_Call_Summary__c WHERE NVMStatsSF__CallGuid__c = 'TestCallGuid001' LIMIT 1];
        
        System.assertNotEquals(null, updatedPCS.Vonage_Call_Summary__c, 'Vonage_Call_Summary__c should have been updated.');
        System.assertEquals(expectedCallSummary.Id, updatedPCS.Vonage_Call_Summary__c, 'Vonage_Call_Summary__c should be updated with the correct Call Summary Id.');
    }
}