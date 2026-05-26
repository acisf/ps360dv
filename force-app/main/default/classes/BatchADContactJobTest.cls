@IsTest
private class BatchADContactJobTest {

    @TestSetup
    static void setupData() {

        // -----------------------
        // Practice Account
        // -----------------------
        Id saRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account practiceAcc = new Account(
            Name='Charlotte - North Carolina',
            Location_Id__c='01002',
            RecordTypeId=saRT
        );
        insert practiceAcc;

        // -----------------------
        // Corporate Account
        // -----------------------
        Id corpRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Appointment').getRecordTypeId();
        Account corpAcc = new Account(
            Name='Affordable Care, LLC',
            Location_Id__c='0',
            RecordTypeId=corpRT
        );
        insert corpAcc;

        // -----------------------
        // Existing Practice Contact
        // -----------------------
        Id practiceContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Practice Employee').getRecordTypeId();
        Contact c1 = new Contact(
            AccountId = practiceAcc.Id,
            FirstName='John',
            LastName='Doe',
            Email='john@example.com',
            RecordTypeId = practiceContactRT
        );
        insert c1;

        // -----------------------
        // Existing Corporate Contact
        //-----------------------
        Id corpContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Corporate Employee').getRecordTypeId();
        Contact c2 = new Contact(
            AccountId = corpAcc.Id,
            FirstName='L',
            LastName='T',
            Email='lester@example.com',
            RecordTypeId = corpContactRT
        );
        insert c2;

        // -----------------------
        // AD_User__c records for CONTACT batch
        // -----------------------
        insert new List<Ad_User__c>{
            // Existing Practice Contact (update)
            new Ad_User__c(
                First_Name__c='John',
                Last_Name__c='DoeUpdated',
                Email__c='john@example.com',
                Phone_Number__c='(555)555-9999',
                Department__c='Dept1',
                Job_Title__c='Physician',
                Active__c=true,
                PracticeDescription__c='01002 Charlotte'
            ),
            // Existing Corporate Contact (update)
            new Ad_User__c(
                First_Name__c='Lester',
                Last_Name__c='TesterUpdated',
                Email__c='lester@example.com',
                Phone_Number__c='(999)999-9999',
                Department__c='Corp',
                Job_Title__c='Manager',
                Active__c=true,
                PracticeDescription__c='Corporate'
            ),
            // New Practice Contact
            new Ad_User__c(
                First_Name__c='New',
                Last_Name__c='Practice',
                Email__c='newpractice@example.com',
                Phone_Number__c='(111)111-1111',
                Department__c='NewDept',
                Job_Title__c='NewTitle',
                Active__c=true,
                PracticeDescription__c='01002 Charlotte'
            ),
            // New Corporate Contact
            new Ad_User__c(
                First_Name__c='New',
                Last_Name__c='Corp',
                Email__c='newcorp@example.com',
                Phone_Number__c='(222)222-2222',
                Department__c='CorpDept',
                Job_Title__c='CorpTitle',
                Active__c=true,
                PracticeDescription__c='Corporate'
            )
        };
    }

    @IsTest
    static void testBatchADContactJob() {

        DateTime dt = System.now().addHours(-1);

        Test.startTest();
        BatchADContactJob batch = new BatchADContactJob(dt);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // -----------------------
        // Validate updates
        //------------------------
        Map<String, Contact> contacts = new Map<String, Contact>();
        List<Contact> lstContacts =[SELECT FirstName, LastName, Email, Work_Phone__c, Department, Title FROM Contact];
        
        for(Contact c: lstContacts) {
            contacts.put(c.Email,c);
        }

        // Updated practice
        Contact c1 = contacts.get('john@example.com');
        System.assertEquals('DoeUpdated', c1.LastName);
        System.assertEquals('(555)555-9999', c1.Work_Phone__c);

        // Updated corporate
        Contact c2 = contacts.get('lester@example.com');
        System.assertEquals('TesterUpdated', c2.LastName);
        System.assertEquals('(999)999-9999', c2.Work_Phone__c);

        // New practice contact
        System.assert(contacts.containsKey('newpractice@example.com'));

        // New corporate contact
        System.assert(contacts.containsKey('newcorp@example.com'));
    }
}