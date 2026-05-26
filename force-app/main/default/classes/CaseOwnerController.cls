public without sharing class CaseOwnerController { 
    
    @AuraEnabled
    public static void invokeAssignmentRules(Id caseId) {
        List<Case> casesToUpdate = [SELECT Id FROM Case WHERE Id =: caseId];
        
        // Check if there are cases to update
        if (!casesToUpdate.isEmpty()) {
            // Create the DMLOptions object to use the assignment rule
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.AssignmentRuleHeader.useDefaultRule = true; 
            dmo.EmailHeader.triggerUserEmail = true;
            // Loop through each case and apply the assignment rule
            for (Case c : casesToUpdate) {
                // Apply the assignment rule to the individual cases
                Database.update(c, dmo);
            }
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Queue__c> getQueuesByDepartment(String departmentName) {
        return [SELECT Id, Queue_Id__c, Name, department__c 
                FROM Queue__c 
                WHERE department__c = :departmentName
                ORDER BY Name];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersByDepartment(String departmentName) {
        return [SELECT Id, User.Name 
                FROM User 
                WHERE Department = :departmentName
                AND isActive = TRUE
                ORDER BY User.Name];
    }
    
    @AuraEnabled    
    public static void sendOwnerNotification(Id caseId) {
        // Retrieve the case to get the new owner
        Case caseRecord = [SELECT Id, OwnerId, Owner.Email, Owner.Type FROM Case WHERE Id = :caseId LIMIT 1];
        
        // Get the Org-Wide Email Address (noreply@affordablecare.com)
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Service Cloud Notification' LIMIT 1];
        
        // Get the Email Template
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'SUPPORT_Case_Transfer' LIMIT 1].Id;
        
        if (caseRecord.OwnerId != null) {
            
            // If the owner is a User, send an email to the user
            String emailAddr = caseRecord.Owner.Email;
            
            if(Test.isRunningTest()) {
                 emailAddr =   UserInfo.getUserEmail();
            }
            if (String.valueOf(caseRecord.OwnerId).startsWith('005') && !String.isEmpty(emailAddr)) {
                sendEmailToUser(emailAddr, emailTemplateId, owea.Id, caseRecord.OwnerId, caseRecord.Id);
            } 
            
            // If the owner is a Queue, handle queue members
            else if (String.valueOf(caseRecord.OwnerId).startsWith('00G')) {
                // Get all direct members of the queue
                List<GroupMember> groupMembers = [
                    SELECT UserOrGroupId 
                    FROM GroupMember 
                    WHERE GroupId = :caseRecord.OwnerId
                ];
                
                // Separate users and groups
                Set<Id> userIds = new Set<Id>();
                Set<Id> groupIds = new Set<Id>();
                
                for (GroupMember member : groupMembers) {
                    if (String.valueOf(member.UserOrGroupId).startsWith('005')) {
                        userIds.add(member.UserOrGroupId);
                    } else if (String.valueOf(member.UserOrGroupId).startsWith('00G')) {
                        groupIds.add(member.UserOrGroupId); // Handle public groups
                    }
                }
                
                // Get users from public groups
                if (!groupIds.isEmpty()) {
                    List<GroupMember> publicGroupMembers = [
                        SELECT UserOrGroupId 
                        FROM GroupMember 
                        WHERE GroupId IN :groupIds
                    ];
                    for (GroupMember member : publicGroupMembers) {
                        if (String.valueOf(member.UserOrGroupId).startsWith('005')) {
                            userIds.add(member.UserOrGroupId);
                        }
                    }
                }
                
                // Fetch user emails and consolidate them into one email
                List<User> queueMembers = [
                    SELECT Id, Email 
                    FROM User 
                    WHERE Id IN :userIds AND IsActive = true
                ];
                
                List<String> toAddresses = new List<String>();
                for (User member : queueMembers) {
                    if (member.Email != null) {
                        toAddresses.add(member.Email);
                    }
                }
                
                if (!toAddresses.isEmpty()) {
                    sendEmailToQueue(toAddresses, emailTemplateId, owea.Id, caseRecord.Id);
                }
            }
        }
    }
    
    // Helper method to send an email to a single user
    private static void sendEmailToUser(String email, Id templateId, Id oweaId, Id userId, Id caseId) {
        Messaging.SingleEmailMessage emailMessage = Messaging.renderStoredEmailTemplate(templateId, userId, caseId);
        emailMessage.setSaveAsActivity(false);
        emailMessage.setToAddresses(new String[] { email });
        emailMessage.setOrgWideEmailAddressId(oweaId);
        emailMessage.setUseSignature(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailMessage });
    }
    
    // Helper method to send an email to multiple queue members
    private static void sendEmailToQueue(List<String> toAddresses, Id templateId, Id oweaId, Id caseId) {
        Messaging.SingleEmailMessage emailMessage = Messaging.renderStoredEmailTemplate(templateId, null, caseId);
        emailMessage.setSaveAsActivity(false);
        emailMessage.setToAddresses(toAddresses);
        emailMessage.setOrgWideEmailAddressId(oweaId);
        emailMessage.setUseSignature(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailMessage });
    }
    
    
    
}