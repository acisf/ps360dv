@IsTest
public class DistanceMatrixServiceTest {
    @IsTest
    public static void testGetNearestPractices() {
        Zip_Code__c zipCode = new Zip_Code__c(zip__c = '12345', latitude__c = 12.345, longitude__c = 67.890, dma__c = 'Test');
        insert zipCode;
        
        Account account1 = new Account(Name = 'Test Account 1', RecordType = new RecordType(Name = 'Schedule Assist'), 
                                       BillingLatitude = 12.345, BillingLongitude = 67.890, Insurance_Accepted__c = 'Insurance 1', dma__c='Test');
        Account account2 = new Account(Name = 'Test Account 2', RecordType = new RecordType(Name = 'Registration'), 
                                       BillingLatitude = 12.355, BillingLongitude = 67.900, Insurance_Accepted__c = 'Insurance 2', dma__c='Test');
        Account account3 = new Account(Name = 'Test Account 3', RecordType = new RecordType(Name = 'Appointment'), 
                                       BillingLatitude = 12.365, BillingLongitude = 67.910, Insurance_Accepted__c = 'Insurance 3', dma__c='Test');
        List<Account> lstAccount = new List<Account>{ account1, account2, account3 };
        insert lstAccount;
        
        Test.setMock(HttpCalloutMock.class, new DistanceMatrixServiceMock());
        
        Test.startTest();
        List<NearestAccount> nearestAccounts = DistanceMatrixService.getNearestPractices('12345');
        List<NearestAccount> accountDistances = DistanceMatrixService.getPracticeDistances('12345', lstAccount);
        Test.stopTest();
        
        Assert.areEqual(3, nearestAccounts.size());
        Assert.areEqual(account1.Id, nearestAccounts[0].recordid);
        Assert.areEqual(160934, nearestAccounts[0].distancevalue);
        Assert.areEqual(account2.Id, nearestAccounts[1].recordid);
        Assert.areEqual(321869, nearestAccounts[1].distancevalue);

        Assert.areEqual(3, accountDistances.size());
        Assert.areEqual(account1.Id, accountDistances[0].recordid);
        Assert.areEqual(160934.0, accountDistances[0].distancevalue);
        Assert.areEqual(account2.Id, accountDistances[1].recordid);
        Assert.areEqual(321869.0, accountDistances[1].distancevalue);
    }
}