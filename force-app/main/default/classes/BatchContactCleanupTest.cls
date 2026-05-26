@isTest
private class BatchContactCleanupTest {

    @isTest
    static void testBatchExecution() {
        // Setup: Create test data
        // Record Types
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Id patientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
       
        Account a = new Account(name='Abilene - Texas',RecordTypeId=RecordTypeIdAcct);
        insert a;
       
        // Contacts
        Contact contact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = a.id,
            CreatedDate = Date.newInstance(2019, 10, 30),
            LastModifiedDate = Date.newInstance(2019, 10, 30),
            RecordTypeId = patientRecordTypeId
        );
        Contact contact2 = new Contact(
             FirstName = 'John',
            LastName = 'Doe',
            AccountId = a.id,
            CreatedDate = Date.newInstance(2019, 10, 30),
            LastModifiedDate = Date.newInstance(2019, 10, 30),
            RecordTypeId = patientRecordTypeId
        );
        insert new List<Contact>{contact1, contact2};

        // Tasks associated with contacts
        Task task1 = new Task(
            WhoId = contact1.Id,
            CreatedDate = Date.newInstance(2019, 10, 15),
            LastModifiedDate = Date.newInstance(2019, 10, 15),
            Status = 'Completed'
        );
        Task task2 = new Task(
            WhoId = contact2.Id,
            CreatedDate = Date.newInstance(2019, 10, 20),
            LastModifiedDate = Date.newInstance(2019, 10, 20),
            Status = 'Completed'
        );
        insert new List<Task>{task1, task2};

        // Run the Batch
        Test.startTest();
        BatchContactCleanup batchJob = new BatchContactCleanup();
        Database.executeBatch(batchJob, 200);  // Batch size set to 200 for test purposes
        Test.stopTest();

        // Assert: Ensure tasks and cases have been deleted
        List<Task> tasksRemaining = [SELECT Id FROM Task WHERE Id IN :new List<Id>{task1.Id, task2.Id}];
        List<Contact> contactsRemaining = [SELECT Id FROM Contact WHERE Id IN :new List<Id>{contact1.Id, contact2.Id}];

        System.assertEquals(0, tasksRemaining.size(), 'All tasks should be deleted');
        System.assertEquals(0, contactsRemaining.size(), 'Contacts should be deleted');
    }

    @isTest
    static void testNoDeletionForFutureModifiedDates() {
        // Setup: Create a contact with LastModifiedDate after the target date
        Id patientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account a = new Account(name='Abilene - Texas',cna_emailoptin__c=true, cna_robocalloptin__c=true,
                                cna_directmailoptin__c=true, recordtypeid=RecordTypeIdAcct);
        insert a;

        Contact contact = new Contact(
             FirstName = 'John',
            LastName = 'Doe',
            AccountId = a.id,
            CreatedDate = Date.newInstance(2020, 1, 1),
            LastModifiedDate = Date.newInstance(2020, 1, 1),
            RecordTypeId = patientRecordTypeId
        );
        insert contact;

        // Task and Case that should not be deleted
        Task task = new Task(
            WhoId = contact.Id,
            CreatedDate = Date.newInstance(2020, 1, 2),
            LastModifiedDate = Date.newInstance(2020, 1, 2),
            Status = 'Completed'
        );
        Case caseRecord = new Case(
            ContactId = contact.Id,
            CreatedDate = Date.newInstance(2020, 1, 2),
            LastModifiedDate = Date.newInstance(2020, 1, 2),
            Status = 'Closed'
        );
        insert new List<SObject>{task, caseRecord};

        // Run the Batch
        Test.startTest();
        BatchContactCleanup batchJob = new BatchContactCleanup();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        // Assert: Verify that task and case were not deleted
        Task taskRemaining = [SELECT Id FROM Task WHERE Id = :task.Id LIMIT 1];
        Case caseRemaining = [SELECT Id FROM Case WHERE Id = :caseRecord.Id LIMIT 1];
        System.assertNotEquals(null, taskRemaining, 'Task with a future LastModifiedDate should not be deleted');
        System.assertNotEquals(null, caseRemaining, 'Case with a future LastModifiedDate should not be deleted');
    }
}