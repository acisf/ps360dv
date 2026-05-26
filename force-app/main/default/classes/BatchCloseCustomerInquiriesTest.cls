@isTest
private class BatchCloseCustomerInquiriesTest {
    
    @isTest
    static void testBatchExecution() {
        // Create a Customer Inquiry record with the last call 72 hours ago
        Customer_Inquiry__c inquiry = new Customer_Inquiry__c(
            CLID__c = '18005551234', // Sample CLID
            First_Call_DateTime__c = DateTime.now().addDays(-5), // First call 5 days ago
            Last_Call_DateTime__c = DateTime.now().addHours(-72), // Last call 72 hours ago
            Closed__c = false // Not closed
        );
        insert inquiry;
        
        Test.startTest();
        // Start the batch job
        Database.executeBatch(new BatchCloseCustomerInquiries(DateTime.now()));
        Test.stopTest();
        
        // Query the Customer Inquiry record
        inquiry = [SELECT Id, Closed__c, Date_Time_Closed__c FROM Customer_Inquiry__c WHERE Id = :inquiry.Id];
        
        // Verify that the inquiry is closed
        System.assertEquals(true, inquiry.Closed__c, 'Expected inquiry to be closed');
        // Verify that Date_Time_Closed__c is not null
        System.assertNotEquals(null, inquiry.Date_Time_Closed__c, 'Expected Date_Time_Closed__c to be set');
    }
}