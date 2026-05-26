@isTest
private class BatchDeleteExtraCaseActivitiesTest {
    @isTest
    static void testBatchDeletesOldActivities() {
        // Create a Case
        Case c = new Case(Subject = 'Test Case', Status = 'New');
        c.CreatedDate = System.now().addDays(-60);
        insert c;

        // Create two Case Activities, one that should be KEPT and one DELETED
        DateTime nowMinus100 = System.now().addDays(-100);
        DateTime nowMinus80  = System.now().addDays(-80);

        // Keeper (earliest, matches rollup First_Response_Time__c)
        Case_Activity__c keeper = new Case_Activity__c(
            Case__c = c.Id,
            Activity_Date_Time__c = nowMinus100,
            Customer_Communication__c = true,
            CreatedDate = nowMinus100
        );

       

        // Non-keeper (but recent, should NOT be touched)
        Case_Activity__c recentExtra = new Case_Activity__c(
            Case__c = c.Id,
            Activity_Date_Time__c = System.now(),
            Customer_Communication__c = true,
            CreatedDate = System.now()
        );

        insert new List<Case_Activity__c>{ keeper,  recentExtra };

        // Simulate what the rollup would hold: min activity datetime 
        update c;

        // Run the batch
        Test.startTest();
        Database.executeBatch(new BatchDeleteExtraCaseActivities(), 50);
        Test.stopTest();

        // Re-query activities
        List<Case_Activity__c> remaining = [
            SELECT Id, Activity_Date_Time__c 
            FROM Case_Activity__c
            WHERE Case__c = :c.Id
        ];

        // We expect keeper and recentExtra to remain, oldExtra to be deleted
        System.assertEquals(1, remaining.size(), 'Only 1 activity should remain');

    }
}