global class BatchCloseCustomerInquiries implements Database.Batchable<sObject> {
     public DateTime endDateTime;
    
    global BatchCloseCustomerInquiries(DateTime dtEnd) {
        endDateTime = dtEnd;
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {
        // Query open Customer Inquiry records
        return Database.getQueryLocator([
            SELECT Id, Last_Call_DateTime__c
            FROM Customer_Inquiry__c
            WHERE Closed__c = false
        ]);
    }
    
    global void execute(Database.BatchableContext context, List<Customer_Inquiry__c> scope) {
        // Set Closed__c = true and Date_Time_Closed__c = current date time for inquiries where 48 hours have passed since the last call
        for (Customer_Inquiry__c inquiry : scope) {
            if (inquiry.Last_Call_DateTime__c != null && this.endDateTime >= inquiry.Last_Call_DateTime__c.addHours(48)) {
                inquiry.Closed__c = true;
                inquiry.Date_Time_Closed__c = inquiry.Last_Call_DateTime__c.addHours(48);
            }
        }
        // Update the records
        update scope;
    }
    
    global void finish(Database.BatchableContext context) {
     }
}