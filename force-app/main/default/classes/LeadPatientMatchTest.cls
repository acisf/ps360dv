@isTest
private class LeadPatientMatchTest {
    
    @isTest
    static void testMatching() {
        
        Id tfRT = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Lead' AND Name = 'Treatment Finder'
            LIMIT 1
        ].Id;
        
        Lead l = new Lead(
            FirstName='John',
            LastName='Doe',
            Email='john@test.com',
            Phone='9191112222',
            Company='Test',
            RecordTypeId=tfRT
        );
        insert l;
        
        Zeta_User__c z = new Zeta_User__c(
            user_Id__c='U1',
            email__c='john@test.com',
            last_name__c='doe',
            phone_appointment__c='9191112222'
        );
        insert z;
        
        insert new List<Zeta_Event__c>{
            new Zeta_Event__c(
                user_id__c='U1',
                event_type__c='new_appt',
                apptdate__c='2026-05-01',
                timestamp__c='2026-05-01T09:00:00'
            ),
            new Zeta_Event__c(
                user_id__c='U1',
                event_type__c='rescheduled_appt',
                apptdate__c='2026-05-05',
                timestamp__c='2026-05-01T10:00:00'
            )
        };
        
        Test.startTest();
        Database.executeBatch(new LeadPatientMatch(Date.today()), 200);
        Test.stopTest();
        
        l = [SELECT First_Appt_Date__c FROM Lead WHERE Id = :l.Id];
        
        System.assertEquals(
            Date.newInstance(2026,5,1),
            l.First_Appt_Date__c
        );
    }
}