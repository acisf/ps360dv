@IsTest
private class FixFBLeadPracticeBatchTest {

    @TestSetup
    static void setupData() {
        // Create Account / Practice
        Account a1 = new Account(
            Name = 'Practice 01002',
            Location_Id__c = '01002',      // use the underlying field
            Brand__c = 'Affordable Dentures & Implants' // use the underlying field
        );
        insert a1;

        // Create a Zip_Code__c record (only set fields that are writable)
        Zip_Code__c zip1 = new Zip_Code__c(
            Zip__c = '12345',
            Practice_1__c = a1.Id
            // Leave Practice_1_Location_Id__c and Practice_1_brand__c blank; formulas will populate them
        );
        insert zip1;

        // FB Leads
        FB_Lead__c leadAd = new FB_Lead__c(
            FB_Ad_Name__c = 'my_adname_01002',
            FB_Practice_Id__c = '00000',
            FB_Practice__c = null
        );

        FB_Lead__c leadZip = new FB_Lead__c(
            FB_Ad_Name__c = 'no_location_ad',
            FB_Zip__c = '12345',
            FB_Practice_Id__c = '00000',
            FB_Practice__c = null
        );

        insert new List<FB_Lead__c>{leadAd, leadZip};
    }

    @IsTest
    static void testBatchFixesAdAndZip() {
        Test.startTest();
        FixFBLeadPracticeBatch batch = new FixFBLeadPracticeBatch();
        Database.executeBatch(batch, 2);
        Test.stopTest();

        // Query updated leads
        List<FB_Lead__c> leads = [
            SELECT FB_Ad_Name__c, FB_Zip__c, FB_Practice_Id__c, FB_Practice__c
            FROM FB_Lead__c
        ];

        for (FB_Lead__c l : leads) {
            if (l.FB_Ad_Name__c.contains('01002')) {
                System.assertEquals('01002', l.FB_Practice_Id__c, 'Ad name should set practice ID');
                System.assertNotEquals(null, l.FB_Practice__c, 'FB_Practice__c should be set for ad');
            } else if (l.FB_Zip__c == '12345') {
                System.assertEquals('01002', l.FB_Practice_Id__c, 'ZIP fallback should set practice ID');
                System.assertNotEquals(null, l.FB_Practice__c, 'FB_Practice__c should be set for zip fallback');
            }
        }
    }
}