global class BatchADUserJob implements Database.Batchable<SObject>, Database.Stateful {

    global DateTime dtStart;

    global BatchADUserJob(DateTime dtStart) {
        this.dtStart = dtStart;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Email__c, First_Name__c, Last_Name__c, Phone_Number__c,
                   Department__c, Job_Title__c, Active__c
            FROM AD_User__c
            WHERE LastModifiedDate >= :dtStart
            AND Email__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<Ad_User__c> adUsers = (List<Ad_User__c>)scope;

        Set<String> emails = new Set<String>();
        for (Ad_User__c ad : adUsers) {
            emails.add(ad.Email__c.toLowerCase());
        }

        Map<String, User> existingUsers = new Map<String, User>();
        for (User u : [
            SELECT Id, Email, FirstName, LastName, Phone,
                   Department, Title, IsActive
            FROM User
            WHERE Email IN :emails
        ]) {
            existingUsers.put(u.Email.toLowerCase(), u);
        }

        List<User> usersToUpdate = new List<User>();

        for (Ad_User__c ad : adUsers) {

            User u = existingUsers.get(ad.Email__c.toLowerCase());
            if (u == null) continue;
            
            if (ad.Active__c == false && u.IsActive == true) { 
                u.IsActive = false; 
                usersToUpdate.add(u);
            }
        }

        if (!usersToUpdate.isEmpty()) {
            update usersToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) { }
}