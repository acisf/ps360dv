@isTest
public class CaseOwnershipChangeTest {
    
    @isTest
    public static void testOwnerChange(){
        Id aceserviceId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ACE Service').getRecordTypeId();
        List<Id> caseId = new List<Id>();   
        List<Id> caseId1 = new List<Id>();
        List<Id> caseId2 = new List<Id>();
        
        Case c = new Case();
        c.Origin = 'Email';
        c.RecordTypeId = aceserviceId;
        c.Team__c = 'IT';
        c.MP_I_Need_Help_With__c = 'Dentrix';
        c.MP_Specifically__c = 'Something else';
        c.Urgency__c = 'We are operational, but need help';         
        insert c;
        
        caseId.add(c.id); 
        
        Group testGroup = new Group(Name='IT: Applications Team', Type='Queue');
        insert testGroup;
        
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }
        
        Case c2 = new Case(OwnerId =testgroup.Id);
        c2.Origin = 'MyPractice';
        c2.RecordTypeId = aceserviceId;
        c2.Team__c = 'IT';
        c2.MP_I_Need_Help_With__c = 'Dentrix';
        c2.MP_Specifically__c = 'Something else';
        c2.Urgency__c = 'We are operational, but need help';     
        insert c2;        
        caseId.add(c2.id); 
        
        Profile p = [Select Id from Profile where Name = 'System Administrator'];
        User u = new User(LastName = 'TestUser', email='testuser@affordablecare.com',username='testuser@affordabelcare.com');
        u.primary_queue__c='IT: Applications Team';
        u.EmailEncodingKey='UTF-8';
        u.Alias='test';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.ProfileId = p.id;
        u.TimeZoneSidKey='America/New_York';
        insert u;
        
        //Case c3 = new Case(OwnerId = UserInfo.getUserId());
        Case c3 = new Case();
        c3.OwnerId = u.Id;
        c3.Origin = 'Email';        
        c3.queue_name__c = 'IT: Applications Team';
        c3.RecordTypeId = aceserviceId;
        c3.Team__c = 'IT';
        c3.MP_I_Need_Help_With__c = 'Dentrix';
        c3.MP_Specifically__c = 'Something else';
        c3.Urgency__c = 'We are operational, but need help';     
        insert c3;        
        caseId1.add(c3.id);       
        
        
        Case c4 = new Case();
        c4.OwnerId = u.Id;
        c4.Origin = 'Phone';        
        c4.queue_name__c = null;
        c4.RecordTypeId = aceserviceId;
        c4.Team__c = 'IT';
        c4.MP_I_Need_Help_With__c = 'Dentrix';
        c4.MP_Specifically__c = 'Something else';
        c4.Urgency__c = 'We are operational, but need help';     
        insert c4;        
        caseId2.add(c4.id);
        
        Test.startTest();
        CaseOwnershipChange.caseOwnerChanged(caseId);
        CaseOwnershipChange.caseOwnerChanged(caseId1);
        CaseOwnershipChange.caseOwnerChanged(caseId2);
        Test.stopTest();        
        
        c = [Select Id, CaseNumber, OwnerId from Case where Id =: c.Id];
        System.assert(c.OwnerId != Null);
        
        c2 = [Select Id, CaseNumber, OwnerId from Case where Id =: c2.Id];
        System.assert(c2.OwnerId != Null);
        
        c3 = [Select Id, CaseNumber, OwnerId from Case where Id =: c3.Id];
        System.assert(c3.OwnerId != Null);
        
        c4 = [Select Id, CaseNumber, OwnerId from Case where Id =: c4.Id];
        System.assert(c4.OwnerId != Null);
        
        
    }
}