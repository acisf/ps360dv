//to run: QueueReportJob.runQueueReport();

public class QueueReportJob {
    public static void runQueueReport() {
        // Step 1: Get all Queues
        Map<Id, Group> queues = new Map<Id, Group>(
            [SELECT Id, Name FROM Group WHERE Type = 'Queue']
        );

        // Step 2: Get all GroupMembers (Users only)
        List<GroupMember> members = [
            SELECT GroupId, UserOrGroupId
            FROM GroupMember
            WHERE GroupId IN :queues.keySet()
        ];

        // Step 3: Filter for User IDs (start with '005') and prepare report records
        List<Queue_Report__c> reportRecords = new List<Queue_Report__c>();

        for (GroupMember gm : members) {
            if (String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                Group queue = queues.get(gm.GroupId);

                reportRecords.add(new Queue_Report__c(
                    Queue_Id__c = queue.Id,
                    Queue_Name__c = queue.Name,
                    User__c = gm.UserOrGroupId
                    // Active__c will populate automatically from the formula
                ));
            }
        }

        // Step 4: Delete existing records (optional if rebuilding the table)
        delete [SELECT Id FROM Queue_Report__c];

        // Step 5: Insert new report records
        insert reportRecords;
    }
}