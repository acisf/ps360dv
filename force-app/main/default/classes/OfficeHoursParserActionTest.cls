@IsTest
private class OfficeHoursParserActionTest {
    
    @IsTest
    static void testUpdateHours() {
        // 1️⃣ Create a test Account
        Account acc = new Account(Name = 'Test Office');
        insert acc;

        // 2️⃣ Build the test JSON
        String jsonInput = '{ ' +
            '"Mon_Open": "9:00 AM", "Mon_Close": "5:00 PM", ' +
            '"Tue_Open": "9:00 AM", "Tue_Close": "5:00 PM", ' +
            '"Wed_Open": "9:00 AM", "Wed_Close": "5:00 PM", ' +
            '"Thu_Open": "9:00 AM", "Thu_Close": "5:00 PM", ' +
            '"Fri_Open": "9:00 AM", "Fri_Close": "5:00 PM", ' +
            '"Sat_Open": "", "Sat_Close": "", "Sun_Open": "", "Sun_Close": "" }';

        // 3️⃣ Create the request wrapper
        OfficeHoursParserAction.Request req = new OfficeHoursParserAction.Request();
        req.recordId = acc.Id;
        req.outputJson = jsonInput;

        // 4️⃣ Call the method under test
        Test.startTest();
        OfficeHoursParserAction.updateHours(new List<OfficeHoursParserAction.Request>{ req });
        Test.stopTest();

        // 5️⃣ Query the updated record
        Account updated = [
            SELECT Mon_Open__c, Mon_Close__c,
                   Tues_Open__c, Tues_Close__c,
                   Wed_Open__c, Wed_Close__c,
                   Thurs_Open__c, Thurs_Close__c,
                   Fri_Open__c, Fri_Close__c,
                   Sat_Open__c, Sat_Close__c
            FROM Account
            WHERE Id = :acc.Id
            LIMIT 1
        ];

        // 6️⃣ Assertions
        System.assertEquals('9:00 AM', updated.Mon_Open__c, 'Monday open should match');
        System.assertEquals('5:00 PM', updated.Mon_Close__c, 'Monday close should match');
        System.assertEquals('9:00 AM', updated.Tues_Open__c, 'Tuesday open should match');
        System.assertEquals('5:00 PM', updated.Tues_Close__c, 'Tuesday close should match');
        System.assertEquals('9:00 AM', updated.Fri_Open__c, 'Friday open should match');
        System.assertEquals(null, updated.Sat_Open__c, 'Saturday open should be blank');
    }
}