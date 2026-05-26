public class SchedulingRequirementsTriggerHandler {

    public static void handle(List<Scheduling_Requirements__c> newRecords) {
        for (Scheduling_Requirements__c sr : newRecords) {
            if (sr.Scheduling_Requirement_Note__c != null) {
                String plainText = sr.Scheduling_Requirement_Note__c.replaceAll('<[^>]+>', ' ');
                plainText = plainText.replaceAll('^\\p{IsWhite_Space}+|\\p{IsWhite_Space}+$', '');
                plainText = plainText.replace('     ', '');
                sr.Scheduling_Requirement_PlainText__c = plainText.unescapeHtml4().trim();
            }
        }
    }
}