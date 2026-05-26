@isTest
public class AccountGeoLogicTest {
    
    private static Id getRecordTypeId(String name) {
        RecordType rt = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Account' AND Name = :name 
            LIMIT 1
        ];
        return rt.Id;
    }
    
    @isTest
    static void testGetAccountByGeoLoc() {
        Id rtId = getRecordTypeId('Schedule Assist');
        
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Springdale',
                BillingStreet = '123 Main St',
                BillingCity = 'Springdale',
                BillingState = 'Arizona',
                BillingPostalCode = '72764',
                BillingLatitude = 36.1867,
                BillingLongitude = -94.1288,
                RecordTypeId = rtId,
                IsClosed__c = false,
                Insurance_Accepted__c = 'Yes',
                Medicaid_Type__c = 'Type A'
            ),
            new Account(
                Name = 'Springfield',
                BillingStreet = '456 Oak St',
                BillingCity = 'Springfield',
                BillingState = 'Massachusetts',
                BillingPostalCode = '01103',
                BillingLatitude = 42.1015,
                BillingLongitude = -72.5898,
                RecordTypeId = rtId,
                IsClosed__c = false,
                Insurance_Accepted__c = 'Yes',
                Medicaid_Type__c = 'Type B'
            )
        };
        insert accounts;
        
        Test.startTest();
        List<SObject> results = AccountGeoLogic.getAccountByGeoLoc(36.1867, -94.1288, 0);
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Expected some accounts returned');
        System.assertEquals('Springdale', (String)results[0].get('Name'));
    }
    
    @isTest
    static void testGetAccountByGeoLoc_NoResults() {
        Test.startTest();
        List<SObject> results = AccountGeoLogic.getAccountByGeoLoc(0, 0, 0);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Expected no accounts returned for invalid geolocation');
    }
    
    @isTest
    static void testConstructorAndProperties() {
        // Insert a contact to use with StandardController
         Id rtId = getRecordTypeId('Schedule Assist');
        Account a = new Account(
                Name = 'Springdale',
                BillingStreet = '123 Main St',
                BillingCity = 'Springdale',
                BillingState = 'Arizona',
                BillingPostalCode = '72764',
                BillingLatitude = 36.1867,
                BillingLongitude = -94.1288,
                RecordTypeId = rtId,
                IsClosed__c = false,
                Insurance_Accepted__c = 'Yes',
                Medicaid_Type__c = 'Type A');
        insert a;
        Contact c = new Contact(LastName = 'Tester',FirstName = 'Test',AccountId=a.id);
        insert c;
        
        // Construct using a StandardController
        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        AccountGeoLogic logic = new AccountGeoLogic(sc);
        
        // Contact should be cloned into cont
        System.assertNotEquals(null, logic.cont, 'Contact property should be set');
        System.assertEquals('Tester', logic.cont.LastName, 'Contact last name should match');
        
        // Test accId property getter/setter
        logic.accId = '001xx000003DHP0';
        System.assertEquals('001xx000003DHP0', logic.accId, 'accId property should retain value');
    }
    
    @isTest
    static void testGoogleApiKeyGetter() {
        // Insert mock custom setting for key
        Google_API_Key_Gen__c setting = new Google_API_Key_Gen__c(
            Name = 'Default',
            Key_Prod__c = 'TEST_KEY'
        );
        insert setting;
        
                 Id rtId = getRecordTypeId('Schedule Assist');
        Account a = new Account(
                Name = 'Springdale',
                BillingStreet = '123 Main St',
                BillingCity = 'Springdale',
                BillingState = 'Arizona',
                BillingPostalCode = '72764',
                BillingLatitude = 36.1867,
                BillingLongitude = -94.1288,
                RecordTypeId = rtId,
                IsClosed__c = false,
                Insurance_Accepted__c = 'Yes',
                Medicaid_Type__c = 'Type A');
        insert a;
        Contact c = new Contact(LastName = 'APIKey',FirstName='Test',AccountId=a.id);
        insert c;
        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        AccountGeoLogic logic = new AccountGeoLogic(sc);
        
        String key = logic.googleAPIKey;
        System.assertEquals('TEST_KEY', key, 'googleAPIKey getter should return the custom setting value');
    }
}