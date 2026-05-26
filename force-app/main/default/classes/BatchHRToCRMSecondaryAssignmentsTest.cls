@IsTest
private class BatchHRToCRMSecondaryAssignmentsTest {

    @IsTest
    static void testSecondaryAssignmentContactLinking() {

        Date importDate = Date.today();

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
        
        Contact c = new Contact(
            FirstName = 'Jane',
            LastName  = 'Doe',
            Employee_Number__c = 'EMP100',
            Email = 'jane.doe@test.com',
            AccountId = practiceAcc.Id
        );
        insert c;

        /* ================================
           HR ROWS
           ================================ */
        HR_Data__c hrWithMatch = new HR_Data__c(
            Employee_Number__c = 'EMP100',
            Import_Date__c = importDate,
            Primary_Job_Assignment__c = 'No',
            Employment_Status__c = 'Active'
        );

        HR_Data__c hrWithoutMatch = new HR_Data__c(
            Employee_Number__c = 'EMP999',
            Import_Date__c = importDate,
            Primary_Job_Assignment__c = 'No',
            Employment_Status__c = 'Active'
        );

        insert new List<HR_Data__c>{ hrWithMatch, hrWithoutMatch };

        /* ================================
           EXECUTE
           ================================ */
        Test.startTest();
        Database.executeBatch(
            new BatchHRToCRMSecondaryAssignments(importDate),
            200
        );
        Test.stopTest();

        /* ================================
           RE-QUERY + MAP BY EMP #
           ================================ */
        Map<String, HR_Data__c> hrByEmpNum = new Map<String, HR_Data__c>();
        for (HR_Data__c hr : [
            SELECT Employee_Number__c, Contact__c
            FROM HR_Data__c
            WHERE Import_Date__c = :importDate
        ]) {
            hrByEmpNum.put(hr.Employee_Number__c, hr);
        }

        /* ================================
           ASSERTIONS
           ================================ */

        System.assertNotEquals(
            null,
            hrByEmpNum.get('EMP100'),
            'Expected HR row for EMP100'
        );

        System.assertEquals(
            c.Id,
            hrByEmpNum.get('EMP100').Contact__c,
            'HR row should be linked to existing Contact'
        );

        System.assertEquals(
            null,
            hrByEmpNum.get('EMP999').Contact__c,
            'HR row without matching Contact should remain unlinked'
        );
    }
    
    	@IsTest
	static void testSecondaryAssignmentPreStartContactLinking() {
    	Date importDate = Date.today();

    	Account practiceAcc = new Account(
        	Name = 'Practice 12345',
        	Location_Id__c = '12345'
    	);
    	insert practiceAcc;

    	Contact c = new Contact(
        	FirstName = 'John',
        	LastName  = 'PreStart',
        	Employee_Number__c = 'EMP200',
        	Email = 'john.prestart@test.com',
        	AccountId = practiceAcc.Id
    	);
    	insert c;

    	HR_Data__c hrPreStart = new HR_Data__c(
        	Employee_Number__c = 'EMP200',
        	Import_Date__c = importDate,
        	Primary_Job_Assignment__c = 'No',
        	Employment_Status__c = 'Pre-Start'
    	);
    	insert hrPreStart;

    	Test.startTest();
    	Database.executeBatch(
        	new BatchHRToCRMSecondaryAssignments(importDate),
        	200
    	);
    	Test.stopTest();

    	HR_Data__c result = [
        	SELECT Contact__c
        	FROM HR_Data__c
        	WHERE Employee_Number__c = 'EMP200'
    	];

    	System.assertEquals(
        	c.Id,
        	result.Contact__c,
        	'Pre-Start HR row should be linked to existing Contact'
    	);
	}
}