@isTest
public class ContactPatientMatchBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Insert test data: zeta user
        Zeta_User__c zUser1 = new Zeta_User__c(
            JSON__c = '{"user_id":"4779842","signed_up_at":"06/04/2018","patient_id":"33600","practice_id":"01001","first_name":"John","last_name":"Smith","contacts":[{"contact_type":"phone","contact_value":"9195551111"}],"home_phone":"9195151111","mobile_phone":"9195551111","work_phone":"","phone_appointment":"9195551111","street":"111 Shade Ln","street2":"","city":"Tampa","state":"FL","zip":"33617","gender":"m","dob":"1/1/1998","chartid":"034373","new_patient":"true","dismissed":"false"}'
        );
        
        Zeta_User__c zUser2 = new Zeta_User__c(
            JSON__c = '{"user_id":"5558421","signed_up_at":"06/04/2020","patient_id":"33601","practice_id":"1001","first_name":"Jane","last_name":"Doe","contacts":[{"contact_type":"email","contact_value":"janedoe@example.com"}],"home_phone":"9195551212","mobile_phone":"9195551212","work_phone":"","phone_appointment":"9195551212","street":"111 Shade Ln","street2":"","city":"Tampa","state":"FL","zip":"33617","gender":"m","dob":"12/21/1998","chartid":"034374","new_patient":"true","dismissed":"false"}'
        );
        
        // 3rd user with a pending dial entry 
        Zeta_User__c zUser3 = new Zeta_User__c(
            JSON__c = '{"user_id":"9999999","signed_up_at":"06/04/2021","patient_id":"33602","practice_id":"01001","first_name":"Mike","last_name":"Tester","contacts":[{"contact_type":"phone","contact_value":"9195551313"}],"home_phone":"9195551313","mobile_phone":"9195551313","street":"123 Test St","city":"Tampa","state":"FL","zip":"33617","gender":"m","dob":"1/1/1990","chartid":"034375","new_patient":"true","dismissed":"false"}'
        );
        insert new List<Zeta_User__c>{zUser1, zUser2, zUser3};
        
        // Insert test data: zeta events
        Zeta_Event__c zEvent1 = new Zeta_Event__c(
            JSON__c = '{"user_id":"5558421","event_type":"new_appt","timestamp":"2021-10-23T15:31:00Z","practiceid":"01001","apptid":"154905","apptdate":"10/29/2021","appttime":"08:00:00 AM","apptdatetime":"2021-10-29T12:00:00Z"}'
        );
        
        Zeta_Event__c zEvent2 = new Zeta_Event__c(
            JSON__c = '{"user_id":"4779842","event_type":"new_appt","timestamp":"2021-10-23T15:31:00Z","practiceid":"01001","apptid":"154903","apptdate":"10/29/2021","appttime":"011:00:00 AM","apptdatetime":"2021-10-29T11:00:00Z"}'
        );
        
        Zeta_Event__c zEvent3 = new Zeta_Event__c(
             JSON__c = '{"user_id":"9999999","event_type":"new_appt","timestamp":"2021-10-23T15:31:00Z","practiceid":"01001","apptid":"154999","apptdate":"10/29/2021","appttime":"10:00:00 AM","apptdatetime":"2021-10-29T14:00:00Z"}'
        );
        
        insert new List<Zeta_Event__c>{zEvent1, zEvent2, zEvent3};
        
        //Insert test data: accounts
         //test data: facebook lead
        Account a = new Account(name='Asheville',Location_Id__c= '01001');
        insert a; 
        
        // Insert test data: contacts
        Id patientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
        Contact contact1 = new Contact(
            FirstName = 'John',
            LastName = 'Smith',
            Email = 'john.smith@example.com',
            Phone = '9195551111',
            MobilePhone = '9195551111',
            OtherPhone = '9195151111',
            AccountId = a.id,
            RecordTypeId = patientRecordTypeId
        );
        
        Contact contact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'janedoe@example.com',
            Phone = '9195551212',
            MobilePhone = '9195551212',
            OtherPhone = '9195551212',
            AccountId = a.id,
            RecordTypeId = patientRecordTypeId
        );
        
        Contact contact3 = new Contact(
            FirstName = 'Mike',
    		LastName = 'Tester',
    		Email = 'mike.tester@example.com',
    		Phone = '9195551313',
    		MobilePhone = '9195551313',
    		AccountId = a.Id,
    		RecordTypeId = patientRecordTypeId
		);
        
        insert new List<Contact>{contact1, contact2, contact3};
        
                              
        // Insert test data: cases
        Case case1 = new Case(
            Status = 'Open',
            ContactId = contact1.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Outbound Campaign').getRecordTypeId()
        );
        
        Case case2 = new Case(
            Status = 'Open',
            ContactId = contact2.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Outbound Campaign').getRecordTypeId()
        );
        
        Case case3 = new Case(
    		Status = 'Open',
   		 	ContactId = contact3.Id,
    		RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Outbound Campaign').getRecordTypeId()
		);
        
        insert new List<Case>{case1, case2, case3};
            
        NVMConnect__DialList__c dialList = new NVMConnect__DialList__c(
        Name = 'Test Dial List'
    	);
    	insert dialList;
        
        // Create a Pending Dial Entry tied to this case
  		NVMConnect__PendingDialEntry__c pde = new NVMConnect__PendingDialEntry__c(
    	NVMConnect__Primary_Phone__c = '919-555-1313',
    	NVMConnect__FreshAt__c = System.now(),
    	NVMConnect__Dial_List__c = dialList.Id,
    	NVMConnect__Indexed_Focus_Object_Id__c = case3.Id 
		);
		insert pde;
    }
    
    @isTest
    static void testBatch() {
        Test.startTest();
        
        // new test
            // Get the "Tester" case (third user added in @testSetup)
    	Case testerCase = [
        	SELECT Id FROM Case WHERE Contact.LastName = 'Tester' LIMIT 1
    	];

    	// Verify PDE exists before batch
    	System.assertEquals(
        	1,
        	[SELECT COUNT() FROM NVMConnect__PendingDialEntry__c 
        	 WHERE NVMConnect__Indexed_Focus_Object_Id__c = :testerCase.Id],
        	'PDE should exist before batch'
    	);
        // end 
        
        Date dtCreated = Date.today();
        ContactPatientMatchBatch batchJob = new ContactPatientMatchBatch(dtCreated);
        Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        // Verify the contacts have been updated
        List<Contact> updatedContacts = [SELECT Id, LastName, Last_Appt_Date__c, Last_Appt_Status__c, Pat_ID_DB__c FROM Contact];
        System.assertEquals(3, updatedContacts.size());
        
        for (Contact contact : updatedContacts) {
            if (contact.LastName == 'Smith') {
                System.assertEquals('4779842', contact.Pat_ID_DB__c, 'Pat_ID_DB__c should be set correctly for John Smith');
                System.assertEquals(Date.newInstance(2021, 10, 29), contact.Last_Appt_Date__c, 'Last_Appt_Date__c should be set correctly for John Smith');
                System.assertEquals('new appt', contact.Last_Appt_Status__c, 'Last_Appt_Status__c should be set correctly for John Smith');
            } else if (contact.LastName == 'Doe') {
                System.assertEquals('5558421', contact.Pat_ID_DB__c, 'Pat_ID_DB__c should be set correctly for Jane Doe');
                System.assertEquals(Date.newInstance(2021, 10, 29), contact.Last_Appt_Date__c, 'Last_Appt_Date__c should be set correctly for Jane Doe');
                System.assertEquals('new appt', contact.Last_Appt_Status__c, 'Last_Appt_Status__c should be set correctly for Jane Doe');
            } else if (contact.LastName == 'Tester') {   
        		System.assertEquals('9999999', contact.Pat_ID_DB__c, 'Pat_ID_DB__c should be set correctly for Tester');
        		System.assertEquals(Date.newInstance(2021, 10, 29), contact.Last_Appt_Date__c, 'Last_Appt_Date__c should be set correctly for Tester');
        		System.assertEquals('new appt', contact.Last_Appt_Status__c, 'Last_Appt_Status__c should be set correctly for Tester');
    		}
        }
          
        // Verify the cases have been closed
        List<Case> updatedCases = [SELECT Id, Status, ContactId FROM Case WHERE Status = 'Closed'];
        System.assertEquals(3, updatedCases.size(), 'All open cases should be closed');
        
        // Verify PDE has been deleted
        Integer pdeCount = [SELECT COUNT() FROM NVMConnect__PendingDialEntry__c 
                        WHERE NVMConnect__Indexed_Focus_Object_Id__c = :testerCase.Id];
    	System.assertEquals(0, pdeCount, 'Pending Dial Entry for Tester case should be deleted');
    }
       
}