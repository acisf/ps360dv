@isTest
public class InsIntakeJobTest {
    
    static testMethod void testJob() {
        
        DateTime dtStart = DateTime.now();
        
        Id RecordTypeIdAcct = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        Account a = new Account(name='Asheville - North Carolina', recordtypeid=RecordTypeIdAcct,
                               location_id__c = '01001');
        insert a;
        
         Contact c = new Contact(firstname='John',lastname='Doe',email='jdoe@example.com');
        c.accountid = a.id;
        insert c; 
        
        Insurance_Intake__c it = new Insurance_Intake__c();
        it.Appointment_Date__c = Date.newInstance(2022,01,01);
        it.Patient_Name__c =c.id;
        it.Insurance_Carrier__c = 'Metlife';
        it.Subscriber_ID_Member_ID__c = '111111';
        it.Patient_DOB__c = Date.newInstance(1970,01,01);
        it.Group__c = '111111';
        it.Plan__c = '111111';
        insert it; 
        
        
        DateTime dtEnd = DateTime.now();
        
        //test getting intakes
        List<Insurance_Intake__c> lstIntake = InsIntakeJob.getIntakes(dtStart, dtEnd);
        System.assertEquals(1,lstIntake.size());
        
        Set<string> PracticesLocationIds= InsIntakeJob.getPracticesLocationIds(lstIntake);
        System.assertEquals(1,PracticesLocationIds.size());
        
        Set<Id> PracticeIds = InsIntakeJob.getPracticeIds(PracticesLocationIds);
        System.assertEquals(1,PracticeIds.size());
        
        Map<Id,string> FDAs = InsIntakeJob.getFDAs(PracticeIds);
         System.assertEquals(1,FDAs.size());
        
        Map<Id,string> PracticeNames = InsIntakeJob.getPracticeNames(PracticeIds);
         System.assertEquals(1,PracticeNames.size());
        
        String strHTM = InsIntakeJob.getEmailBody(lstIntake[0].Practice_Id__c, dtStart, dtEnd, lstIntake);
        System.assertNotEquals('',strHTM);
        
        //to do, make sure it's afternoon for 0, evening for 1, nothing happens otherwise
        InsIntakeJob.runReports(0);
        Integer invocations = Limits.getEmailInvocations();
        System.assertEquals(1, invocations);
    }
}