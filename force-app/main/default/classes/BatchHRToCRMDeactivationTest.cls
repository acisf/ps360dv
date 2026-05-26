@IsTest
private class BatchHRToCRMDeactivationTest {

    @TestSetup
    static void setup() {

        // -------------------------------------------------
        // Accounts
        // -------------------------------------------------
        Account dso = new Account(Name = 'Affordable Care, LLC');
        Account practice = new Account(
            Name = 'Practice 01001',
            Location_ID__c = '01001'
        );
        insert new List<Account>{ dso, practice };

        // -------------------------------------------------
        // Contacts
        // -------------------------------------------------
        Contact jane = new Contact(
            AccountId = practice.id,
            FirstName = 'Jane',
            LastName = 'Doe',
            Employee_Number__c = 'EMP001',
            Active_Contact__c = true
        );

        Contact john = new Contact(
            AccountId = practice.id,
            FirstName = 'John',
            LastName = 'Smith',
            Employee_Number__c = 'EMP002',
            Active_Contact__c = true
        );

        insert new List<Contact>{ jane, john };

        // -------------------------------------------------
        // HR Snapshot (authoritative)
        // -------------------------------------------------
        insert new List<HR_Data__c>{
            // Jane active – practice
            new HR_Data__c(
                Employee_Number__c = 'EMP001',
                Practice_ID__c = '01001',
                Contact__c = jane.id,
                Department_Reference_Code__c = 'PRIMARY',
                Employment_Status__c = 'Active',
                Import_Date__c = Date.today()
            ),
            // Jane active – corporate
            new HR_Data__c(
                Employee_Number__c = 'EMP001',
                Practice_ID__c = 'MSC',
				Contact__c = jane.id,
                Department_Reference_Code__c = 'OWNER',
                Employment_Status__c = 'Active',
                Import_Date__c = Date.today()
            ),
            // John terminated
            new HR_Data__c(
                Employee_Number__c = 'EMP002',
                Practice_ID__c = '01001',
                Contact__c = john.id,
                Department_Reference_Code__c = 'HYGIENE',
                Employment_Status__c = 'Terminated',
                Import_Date__c = Date.today()
            )
        };

        // -------------------------------------------------
        // Location Assignments (pre-existing)
        // -------------------------------------------------
        insert new List<Location_Assignment__c>{
            // Jane valid assignment
            new Location_Assignment__c(
                External_Key__c = jane.Id + '-' + practice.Id + '-PRIMARY',
                Contact__c = jane.Id,
                Account__c = practice.Id,
                Department_Ref_Code__c = 'PRIMARY'
            ),
            // Jane stale assignment (should be deleted)
            new Location_Assignment__c(
                External_Key__c = jane.Id + '-' + practice.Id + '-OLD',
                Contact__c = jane.Id,
                Account__c = practice.Id,
                Department_Ref_Code__c = 'OLD'
            ),
            // John assignment (terminated → delete)
            new Location_Assignment__c(
                External_Key__c = john.Id + '-' + practice.Id + '-HYGIENE',
                Contact__c = john.Id,
                Account__c = practice.Id,
                Department_Ref_Code__c = 'HYGIENE'
            )
        };
    }

    @IsTest
    static void testDeactivationLogic() {

        Test.startTest();
        Database.executeBatch(
            new BatchHRToCRMDeactivation(Date.today()),
            50
        );
        Test.stopTest();

        // -------------------------------------------------
        // Validate Contacts
        // -------------------------------------------------
        Map<String, Contact> contacts = new Map<String, Contact>();
        for (Contact c : [
            SELECT Employee_Number__c, Active_Contact__c
            FROM Contact
        ]) {
            contacts.put(c.Employee_Number__c, c);
        }

        System.assertEquals(
            true,
            contacts.get('EMP001').Active_Contact__c,
            'Jane should remain active'
        );

        System.assertEquals(
            false,
            contacts.get('EMP002').Active_Contact__c,
            'John should be deactivated'
        );

       

    }
}