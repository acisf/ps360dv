global class ScheduleDelUnusedRecords implements Schedulable {
    
    global void execute(SchedulableContext SC) {   
                    
        //batch delete archived tasks
        BatchDelete BDel1 = new BatchDelete();
        Datetime d = Datetime.now();
        d = d.addDays(-730);
        BDel1.query = 'select id from task where isArchived = true and NVMContactWorld__CW_Call_Start_Time__c != NULL AND CreatedDate < ' + 
        d.format('yyyy-MM-dd')+'T'+  d.format('HH:mm')+':00.000Z' + ' ALL ROWS';        
        ID batchprocessid1 = Database.executeBatch(BDel1);
        //enable enhanced email
        
        //batch delete case email tasks
        //Disabled 12/18/2023 - dbv - causing an issue with HFD email logging
        /*BatchDelete BDel2 = new BatchDelete();
        d = Datetime.now();
        d = d.addDays(-1);
        BDel2.query = 'SELECT Id, Subject FROM Task where what.type = \'Case\' AND Subject LIKE \'Email:%\' AND CreatedDate < ' +
        d.format('yyyy-MM-dd')+'T'+ d.format('HH:mm')+':00.000Z'; 
        ID batchprocessid2 = Database.executeBatch(BDel2);*/
        
        //batch delete practice review email tasks
        BatchDelete BDel3 = new BatchDelete();
        d = Datetime.now();
        d = d.addDays(-90);
        BDel3.query = 'SELECT Id, Subject FROM Task where what.type = \'practice_review__c\' AND Subject LIKE \'Email:%\' AND CreatedDate < ' +
        d.format('yyyy-MM-dd')+'T'+ d.format('HH:mm')+':00.000Z';        
        ID batchprocessid3 = Database.executeBatch(BDel3);
        
        //batch delete facebook email task
        BatchDelete BDel4 = new BatchDelete();
        d = Datetime.now();
        d = d.addDays(-32);
        BDel4.query = 'SELECT Id, Subject FROM Task where what.type = \'FB_Lead__c\' AND Subject LIKE \'Email:%\' AND CreatedDate < ' +
            d.format('yyyy-MM-dd')+'T'+ d.format('HH:mm')+':00.000Z';        
        ID batchprocessid4 = Database.executeBatch(BDel4);

        //batch delete interaction events 
        BatchDelete BDel5 = new BatchDelete();
        d = Datetime.now();
        d = d.addDays(-32);
        BDel5.query = 'SELECT Id FROM NVMContactWorld__InteractionEvent__c WHERE CreatedDate < ' +
            d.format('yyyy-MM-dd')+'T'+ d.format('HH:mm')+':00.000Z';        
        ID batchprocessid5 = Database.executeBatch(BDel5);

        
        //batch delete zeta users  
        BatchDelete BDel6 = new BatchDelete();
        d = Datetime.now();
        d = d.addDays(-7);
        BDel6.query = 'SELECT Id FROM zeta_user__c WHERE CreatedDate < ' +
             d.format('yyyy-MM-dd')+'T'+ d.format('HH:mm')+':00.000Z';
        ID batchprocessid6 = Database.executeBatch(BDel6);

        //batch delete zeta events
        BatchDelete BDel7 = new BatchDelete();
        d = Datetime.now();
        d = d.addDays(-7);
        BDel7.query = 'SELECT Id FROM zeta_event__c WHERE CreatedDate < ' +
        d.format('yyyy-MM-dd')+'T'+ d.format('HH:mm')+':00.000Z';
        ID batchprocessid7 = Database.executeBatch(BDel7);

        
        //batch delete contacts with no tasks
        BatchDeleteUnusedContacts delCon = new BatchDeleteUnusedContacts();
        DataBase.executeBatch(delCon);
        
    }

}