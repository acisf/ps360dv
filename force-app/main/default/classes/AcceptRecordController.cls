public with sharing class AcceptRecordController {
    @AuraEnabled
    public static void acceptRecord(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is null.');
        }

        List<Patient_Intake__c> records = [
            SELECT Id, OwnerId
            FROM Patient_Intake__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException('Patient Intake record not found for Id: ' + recordId);
        }

        Patient_Intake__c record = records[0];
        record.OwnerId = UserInfo.getUserId();
        update record; //does update
    }
}