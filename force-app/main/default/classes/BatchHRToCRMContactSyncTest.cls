@IsTest
private class BatchHRToCRMContactSyncTest {

    @TestSetup
    static void setupData() {

        // Create Accounts	
        Account practiceAcc = new Account(
            Name = 'Practice 12345',
            Location_Id__c = '12345'
        );
        insert practiceAcc;
        

        Account dsoAcc = new Account(
            Name = 'Affordable Care, LLC',
            Location_Id__c = '0'
        );
        insert dsoAcc;
        
        // Create existing Contact
        Contact existingContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Employee_Number__c = 'EMP001',
            Title = 'FDA',
            AccountId = practiceAcc.Id,
            Active_Contact__c = true,
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
                            .get('Practice Employee').getRecordTypeId()
        );
        insert existingContact;

        // Create HR_Data__c records
        List<HR_Data__c> hrRecords = new List<HR_Data__c>{
            new HR_Data__c(
                Employee_Number__c = 'EMP001',
                Import_Date__c = Date.today(),
                Practice_ID__c = '12345',                
                Primary_Job_Assignment__c = 'Yes',
                First_Name__c = 'Jane',
                Last_Name__c = 'Doe',
                Email_Address__c = 'jane@example.com',
                Employment_Status__c = 'Active'
            ),
                new HR_Data__c(
                Employee_Number__c = 'EMP001',
                Import_Date__c = Date.today(),
                Practice_ID__c = 'MSC',                
                Primary_Job_Assignment__c = 'No',
                First_Name__c = 'Jane',
                Last_Name__c = 'Doe',
                Email_Address__c = 'jane@example.com',
                Employment_Status__c = 'Active'
            ),
            new HR_Data__c(
                Employee_Number__c = 'EMP002',
                Import_Date__c = Date.today(),
                Practice_ID__c = 'MSC',
                Primary_Job_Assignment__c = 'Yes',
                First_Name__c = 'John',
                Last_Name__c = 'Smith',
                Email_Address__c = 'john@example.com',
                Employment_Status__c = 'Active'
            ),
            new HR_Data__c(
                Employee_Number__c = 'EMP003',
                Import_Date__c = Date.today(),
                Practice_ID__c = '12345',
                Primary_Job_Assignment__c = 'Yes',
                First_Name__c = 'Mary',
                Last_Name__c = 'Johnson',
                Email_Address__c = 'mary@example.com',
                Employment_Status__c = 'Active'
            ),
            new HR_Data__c(
                Employee_Number__c = 'EMP004',
                Import_Date__c = Date.today(),
                Practice_ID__c = '12345',
                Primary_Job_Assignment__c = 'Yes',
                First_Name__c = 'Jane',
                Last_Name__c = 'Smith',
                Email_Address__c = 'janes@example.com',
                Employment_Status__c = 'Pre-Start'
            )
        };
        insert hrRecords;
    }

    @IsTest
    static void testBatchExecution() {

        Test.startTest();
        BatchHRToCRMContactSync batchJob = new BatchHRToCRMContactSync(Date.today());
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        // Verify Contacts
        List<Contact> contacts = [SELECT Id, Employee_Number__c, AccountId, RecordTypeId, Active_Contact__c FROM Contact];
        System.assertEquals(4, contacts.size(), 'Four contacts should exist');

        Map<String, Contact> contactMap = new Map<String, Contact>();
        for (Contact c : contacts) contactMap.put(c.Employee_Number__c, c);

        Contact jane = contactMap.get('EMP001');
        System.assertEquals(true, jane.Active_Contact__c, 'Jane should still be active');

        Contact john = contactMap.get('EMP002');
        System.assertEquals(true, john.Active_Contact__c, 'John should be active');
        System.assertEquals(Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Corporate Employee').getRecordTypeId(),
                            john.RecordTypeId, 'John should have Corporate Employee RT');

        Contact mary = contactMap.get('EMP003');
        System.assertEquals(true, mary.Active_Contact__c, 'Mary should be active');
        
        Contact janeSmith = contactMap.get('EMP004');
        System.assertEquals(true, janeSmith.Active_Contact__c, 'Jane Smith should be active');

        List<Batch_Error_Log__c> lstErr = [SELECT External_Id__c, Error_Message__c FROM Batch_Error_Log__c];
        for(Batch_Error_Log__c err: lstErr) {
            System.debug(err.External_Id__c + '|' + err.Error_Message__c);
        }

    }
}