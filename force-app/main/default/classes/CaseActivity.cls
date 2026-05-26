global class CaseActivity {
    @InvocableMethod(label = 'Create Case Activity')
    global static void createCaseActivity(CaseActivities[] activities) {
        try {
            List<Case_Activity__c> case_upd = new List<Case_Activity__c>();
            Set<Id> emailIds = new Set<Id>();
            Set<Id> taskIds = new Set<Id>();
            
            // Separate Email and Task record IDs
            for (CaseActivities ca : activities) {
                if (ca.type == 'Email') {
                    emailIds.add(ca.rec_id);
                } else if (ca.type == 'Task') {
                    taskIds.add(ca.rec_id);
                }
            }

            // Filter out auto-response Emails
            if (!emailIds.isEmpty()) {
                List<EmailMessage> emails = [SELECT Id, Subject FROM EmailMessage WHERE Id IN :emailIds];
                for (EmailMessage email : emails) {
                    if (email.Subject.startsWith('We Hear You') || email.Subject.startsWith('New case') ||
                        email.Subject.startsWith('Email: We Hear You') || email.Subject.startsWith('Email: New case')) {
                        emailIds.remove(email.Id);
                    }
                }
            }

            // Filter out auto-response Tasks
            if (!taskIds.isEmpty()) {
                List<Task> tasks = [SELECT Id, Subject FROM Task WHERE Id IN :taskIds];
                for (Task task : tasks) {
                    if (task.Subject.startsWith('We Hear You') || task.Subject.startsWith('New case') ||
                        task.Subject.startsWith('Email: We Hear You') || task.Subject.startsWith('Email: New case') ||
                        task.Subject.equals('Assigned case using round robin')) {
                        taskIds.remove(task.Id);
                    }
                }
            }
           
            // Create Case Activity records
            for (CaseActivities ca : activities) {
                if (ca.type == 'Email' && emailIds.contains(ca.rec_id)) {
                    // Handle valid email activities
                    Case_Activity__c case_act = new Case_Activity__c();
                    case_act.case__c = ca.caseId;
                    case_act.Activitytype__c = ca.type;
                    case_act.Activity_Date_Time__c = DateTime.now();
                    case_act.Related_Object_Id__c = ca.rec_id;
                    case_upd.add(case_act);
                } else if (ca.type == 'Task' && taskIds.contains(ca.rec_id)) {
                    // Handle valid task activities
                    Case_Activity__c case_act = new Case_Activity__c();
                    case_act.case__c = ca.caseId;
                    case_act.Activitytype__c = ca.type;
                    case_act.Activity_Date_Time__c = DateTime.now();
                    case_act.Related_Object_Id__c = ca.rec_id;
                    case_upd.add(case_act);
                } else if (ca.type != 'Email' && ca.type != 'Task') {
                    // Handle other activity types
                    Case_Activity__c case_act = new Case_Activity__c();
                    case_act.case__c = ca.caseId;
                    case_act.Activitytype__c = ca.type;
                    case_act.Activity_Date_Time__c = DateTime.now();
                    case_act.Related_Object_Id__c = ca.rec_id;
                    case_upd.add(case_act);
                }
            }

            // Insert Case Activity records
            if (!case_upd.isEmpty()) {
                insert case_upd;
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    global class CaseActivities {
        @InvocableVariable(required = true)
        global Id caseId;

        @InvocableVariable(required = true)
        global Id rec_id;

        @InvocableVariable(required = true)
        global String type;
    }
}