@isTest
private class BatchFBLeadToZetaTest {
    
    @isTest
    static void testBatch() {
        // Set up test data
        DateTime yesterday = DateTime.now().addDays(-1);
        
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'TestCo',
            Adibot_How_Soon_Tooth_Replacement__c = 'Soon',
            Adibot_Preventing_Seeking_Treatment__c = 'Cost',
            Adibot_Interested_Financing_Options__c = 'Yes',
            Adibot_What_Dental_Insurance__c = 'Delta Dental',
            Adibot_Type_Dental_Treatment__c = 'Implants',
            Adibot_Have_Dental_Insurance__c = 'Yes',
            ArchieBot_Extractions_NDWP__c = 'No'
        );
        insert testLead;

        FB_Lead__c fbLead = new FB_Lead__c(
            FB_First_Name__c = 'John',
            FB_Last_Name__c = 'Doe',
            FB_Email__c = 'john.doe@example.com',
            FB_Phone__c = '1234567890',
            FB_Ad_Name__c = 'Ad Test',
            FB_Practice_Id__c = '01111',
            Lead__c = testLead.Id,
            CreatedDate = yesterday
        );

        insert fbLead;

        // Run the batch
        Test.startTest();
        Database.executeBatch(new BatchFBLeadToZeta(), 200);
        Test.stopTest();

        // Verify the result
        List<FB_Lead_Zeta__c> results = [SELECT FB_Lead_Id__c, FB_First_Name__c, FB_Email__c,
                                         Treatment_Start_Timeframe__c, Barrier_To_Dental_Care__c,
                                         Interested_In_Financing__c, Dental_Insurance_Provider__c,
                                         Dental_Treatment_Type__c, Has_Dental_Insurance__c,
                                         Requires_Extractions_for_New_Dentures__c
                                         FROM FB_Lead_Zeta__c WHERE FB_Lead_Id__c = :fbLead.Id];

        System.assertEquals(1, results.size(), 'Expected one Zeta record to be created');
        FB_Lead_Zeta__c zeta = results[0];
        System.assertEquals('John', zeta.FB_First_Name__c);
        System.assertEquals('Delta Dental', zeta.Dental_Insurance_Provider__c);
        System.assertEquals('Soon', zeta.Treatment_Start_Timeframe__c);
        System.assertEquals('Yes', zeta.Has_Dental_Insurance__c);
    }

}