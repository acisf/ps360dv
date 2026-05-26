@isTest
private class AcceptRecordControllerTest {

    @isTest
    static void testAcceptRecord_success() {
        // Create test user (optional — current user will be default)
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Create a test Patient Intake record
        Patient_Intake__c intake = new Patient_Intake__c(
            Appointment_Date__c=Date.today()
        );
        insert intake;

        // Call method
        Test.startTest();
        AcceptRecordController.acceptRecord(intake.Id);
        Test.stopTest();

        // Verify owner updated
        Patient_Intake__c updatedRecord = [
            SELECT OwnerId FROM Patient_Intake__c WHERE Id = :intake.Id
        ];

        System.assertEquals(
            u.Id,
            updatedRecord.OwnerId,
            'OwnerId should have been updated to the current user.'
        );
    }

}