@IsTest
private class BatchHRLocationAssignmentTest {

    @IsTest
    static void testBatchLocationAssignment_PrimaryAndSecondary() {

        // ------------------------------------------------------------
        // 1️⃣ Accounts (Practice + DSO)
        // ------------------------------------------------------------
        Account practice = new Account(
            Name = 'Test Practice',
            Location_ID__c = '01001'
        );
        insert practice;

        Account dso = new Account(
            Name = 'Affordable Care, LLC'
        );
        insert dso;

        // ------------------------------------------------------------
        // 2️⃣ Contact (Jane)
        // ------------------------------------------------------------
        Contact jane = new Contact(
            AccountId = practice.id,
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'jane.doe@test.com',
            Employee_Number__c = 'EMP001',
            Active_Contact__c = true
        );
        insert jane;

        Date importDate = Date.today();

        // ------------------------------------------------------------
        // 3️⃣ HR Data (Primary + Secondary + Secondary Append)
        // ------------------------------------------------------------
        List<HR_Data__c> hrRows = new List<HR_Data__c>{

            // Primary Practice
            new HR_Data__c(
                Employee_Number__c = 'EMP001',
                Import_Date__c = importDate,
                Practice_ID__c = '1001', // unpadded on purpose
                Employment_Status__c = 'Active',
                Primary_Job_Assignment__c = 'Yes',
                Department_Name__c = 'Clinical',
                Department_Reference_Code__c = 'PRIMARY',
                Contact__c = jane.Id
            ),

            // Secondary DSO
            new HR_Data__c(
                Employee_Number__c = 'EMP001',
                Import_Date__c = importDate,
                Practice_ID__c = '1001',
                Employment_Status__c = 'Active',
                Primary_Job_Assignment__c = 'No',
                Department_Name__c = 'Practice Owner',
                Department_Reference_Code__c = 'OWNER',
                Contact__c = jane.Id
            ),

            // Secondary DSO (append – new dept)
            new HR_Data__c(
                Employee_Number__c = 'EMP001',
                Import_Date__c = importDate,
                Practice_ID__c = 'DSO',
                Employment_Status__c = 'Active',
                Primary_Job_Assignment__c = 'Yes',
                Department_Name__c = 'Ops',
                Department_Reference_Code__c = 'CCO',
                Contact__c = jane.Id
            )
        };

        insert hrRows;

        // ------------------------------------------------------------
        // 4️⃣ Execute Batch
        // ------------------------------------------------------------
        Test.startTest();
        Database.executeBatch(
            new BatchHRLocationAssignment(importDate),
            200
        );
        Test.stopTest();

        // ------------------------------------------------------------
        // 5️⃣ Assertions
        // ------------------------------------------------------------
        List<Location_Assignment__c> assignments = [
            SELECT Contact__c,
                   Account__c,
                   Primary_Job_Assignment__c,
                   Department_Name__c,
                   Department_Ref_Code__c,
                   External_Key__c
            FROM Location_Assignment__c
            WHERE Contact__c = :jane.Id
        ];

        System.assertEquals(
            3,
            assignments.size(),
            'Jane should have three location assignments (primary + two secondary)'
        );

        // Track keys for validation
        Set<String> deptCodes = new Set<String>(); 
        Set<Id> accountIds = new Set<Id>();

        for (Location_Assignment__c la : assignments) {
            deptCodes.add(la.Department_Ref_Code__c);
            accountIds.add(la.Account__c);

            System.assertNotEquals(
                null,
                la.External_Key__c,
                'External Key should always be populated'
            );
        }

        System.assertEquals(
            new Set<String>{ 'CCO', 'OWNER', 'PRIMARY' },
            deptCodes,
            'All department reference codes should be present'
        );

        System.assert(
            accountIds.contains(practice.Id),
            'Practice assignment should exist'
        );

        System.assert(
            accountIds.contains(dso.Id),
            'DSO assignment should exist'
        );
    }
    
    @IsTest
	static void testBatchLocationAssignment_PreStart() {

    	// ------------------------------------------------------------
    	// 1️⃣ Accounts
    	// ------------------------------------------------------------
    	Account practice = new Account(
        	Name = 'Test Practice 2',
        	Location_ID__c = '02002'
    	);
    	insert practice;

    	Account dso = new Account(
        	Name = 'Affordable Care, LLC'
    	);
    	insert dso;

    	// ------------------------------------------------------------
    	// 2️⃣ Contact
    	// ------------------------------------------------------------
    	Contact john = new Contact(
        	AccountId = practice.Id,
        	FirstName = 'John',
        	LastName = 'PreStart',
        	Email = 'john.prestart@test.com',
        	Employee_Number__c = 'EMP002',
        	Active_Contact__c = true
    	);
    	insert john;

    	Date importDate = Date.today();

    	// ------------------------------------------------------------
    	// 3️⃣ HR Data — Pre-Start status
    	// ------------------------------------------------------------
    	HR_Data__c hrRow = new HR_Data__c(
        	Employee_Number__c = 'EMP002',
        	Import_Date__c = importDate,
        	Practice_ID__c = '2002',
        	Employment_Status__c = 'Pre-Start',
        	Primary_Job_Assignment__c = 'Yes',
        	Department_Name__c = 'Clinical',
        	Department_Reference_Code__c = 'PRIMARY',
        	Contact__c = john.Id
    	);
    	insert hrRow;

    	// ------------------------------------------------------------
    	// 4️⃣ Execute Batch
    	// ------------------------------------------------------------
    	Test.startTest();
    	Database.executeBatch(
        	new BatchHRLocationAssignment(importDate),
        	200
    	);
    	Test.stopTest();

    	// ------------------------------------------------------------
    	// 5️⃣ Assertions
    	// ------------------------------------------------------------
    	List<Location_Assignment__c> assignments = [
        	SELECT Contact__c,
               	Account__c,
               	Active__c,
               	Department_Ref_Code__c,
               	External_Key__c
        	FROM Location_Assignment__c
        	WHERE Contact__c = :john.Id
    	];

    	System.assertEquals(
        	1,
        	assignments.size(),
        	'Pre-Start employee should have one location assignment'
    	);

    	System.assertEquals(
        	true,
        	assignments[0].Active__c,
        	'Pre-Start location assignment should be active'
    	);

    	System.assertNotEquals(
        	null,
        	assignments[0].External_Key__c,
        	'External Key should be populated'
    	);

    	System.assertEquals(
        	practice.Id,
        	assignments[0].Account__c,
        	'Assignment should be linked to the correct practice account'
    	);
	}
}