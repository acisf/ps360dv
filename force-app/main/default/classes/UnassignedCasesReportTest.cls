@isTest
public class UnassignedCasesReportTest {

    @isTest
    public static void testSendReport(){    
        Id qId;
        
        Test.startTest();         
        User u = new User(
                 ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            	 FirstName = 'Test1',
                 LastName = 'User1',
                 Email = 'test1.user1@example.com',
                 Username = 'test1.user1@example.com' + System.currentTimeMillis(),
                 CompanyName = 'TEST',
                 Title = 'title',
                 Alias = 'alias',
                 TimeZoneSidKey = 'America/Los_Angeles',
                 EmailEncodingKey = 'UTF-8',
                 LanguageLocaleKey = 'en_US',
                 LocaleSidKey = 'en_US'                
            );
        insert u;  
        
        System.runAs(u){
            Group publicGroup = new Group(name = 'IT Group', type = 'Regular');
            insert publicGroup;
            
            GroupMember gpm = new GroupMember();
            gpm.GroupId = publicGroup.id;
            gpm.UserOrGroupId = u.id;
            insert gpm;
            
            Group queue = new Group(name = 'IT:Applications Team', type = 'Queue');
            insert queue;
            QueuesObject testQueue = new QueueSObject(QueueID = queue.id, SObjectType = 'Case');
            insert testQueue;
            qId = queue.Id;
            
            GroupMember qmem = new GroupMember();
            qmem.GroupId = queue.id;
            qmem.UserOrGroupId = publicGroup.id;
            insert qmem; 
        }
        
        Test.stopTest();
        
        Id aceId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ACE Service').getRecordTypeId();
        Case c = new Case();
        c.subject = 'Test case 1';
        c.Description = 'Test case 1';
        c.RecordTypeId = aceId;
        c.OwnerId = qId;
        insert c;        
        
        System.assertEquals(1, Limits.getEmailInvocations(), 'Auto response email should be sent');
       	UnassignedCasesReport.sendUnassignedCasesReport('IT:Applications Team');
        System.assertEquals(2, Limits.getEmailInvocations(), 'Unassigned cases report emails should be sent');
        
    }
}