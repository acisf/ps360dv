@isTest
public class DeleteArchivedTasksTest {

    @isTest ()
    public static void getArchivedTasks()
    {
           Task t = new Task();
        t.Priority = 'High';
        t.OwnerId = userInfo.getUserId();
        t.ActivityDate = Date.newInstance(2018, 12, 21);
        t.Subject = 'Test Task';
        t.Status = 'Completed';
        insert t;
        
      
        Test.startTest();
        Id batchId = Database.executeBatch(new DeleteArchivedTasks());
        Test.stopTest();
          List<Task> tsk = [Select id from Task];
        System.assert(tsk.size() == 0);
        
       /* Account acc = new Account(name = 'Acc1');
        insert acc;
        
        Task t = new Task();
        t.Priority = 'High';
        t.OwnerId = userInfo.getUserId();
        t.ActivityDate = Date.newInstance(2018, 12, 21);
        t.WhatId = acc.id;
        t.Subject = 'Test Task';
        t.Status = 'Completed';
        insert t;
        
        Task t1 = [Select id, isArchived, WhatId, Subject from Task where WhatId = :acc.id limit 1];
        System.debug(t1.Id + ' ' + t1.IsArchived + ' ' + t1.WhatId + ' ' + t1.Subject);
        System.debug(acc.Name + ' ' + acc.id);*/
        
    }
}