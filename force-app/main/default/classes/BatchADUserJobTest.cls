@IsTest
private class BatchADUserJobTest {

    @TestSetup
    static void setupTestData() {

        // -----------------------
        // Existing User
        // -----------------------
        User u = new User(
            Username= 'juser@example.com',
            FirstName='John',
            LastName='User',
            Email='juser@example.com',
            Alias='juser',
            Phone='(804)555-1212',
            Department='Test',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey='en_US',
            IsActive = true
        );
        insert u;

        // -----------------------
        // AD_User__c records for USER batch
        // -----------------------
        List<Ad_User__c> adUsers = new List<Ad_User__c>{
            new Ad_User__c(
                First_Name__c='John',
                Last_Name__c='User',
                Email__c='juser@example.com',
                Phone_Number__c='(804)555-1212',
                Department__c='Test',
                Active__c=false
            ),
            // AD user with no matching User (should simply be skipped)
            new Ad_User__c(
                First_Name__c='No',
                Last_Name__c='UserMatch',
                Email__c='nouser@example.com',
                Phone_Number__c='(000)000-0000',
                Department__c='None',
                Job_Title__c='None',
                Active__c=false
            )
        };
        insert adUsers;
    }

    @IsTest
    static void testBatchADUserJob() {

        DateTime dt = System.now().addHours(-1);

        Test.startTest();
        BatchADUserJob batch = new BatchADUserJob(dt);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // -----------------------
        // Validate existing User updated
        //------------------------
        List<User> lstU;
        lstU = [SELECT FirstName, LastName, Phone, Department, Title, IsActive FROM User WHERE Email = 'juser@example.com' ];
        User updated = lstU[0];

        System.assert(updated.IsActive == false);
    }
}