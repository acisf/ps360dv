public class FirstCallResolutionBatch1 implements Database.Batchable<sObject>,Database.Stateful {
    
    public DateTime callEndDateTime;
    
    public FirstCallResolutionBatch1(DateTime callEnd) {
        callEndDateTime = callEnd;
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Calculate the start date one day prior to the end date
        DateTime callStartDateTime = callEndDateTime.addDays(-1);
        
        // Query NVMStatsSF__NVM_Call_Summary__c records within the 24-hour window
        return Database.getQueryLocator([
            SELECT Id, NVMStatsSF__CLID__c, NVMStatsSF__CallTime__c,NVMStatsSF__Related_Contact__c
            FROM NVMStatsSF__NVM_Call_Summary__c
            WHERE NVMStatsSF__CallTime__c >= :callStartDateTime
            AND NVMStatsSF__CallTime__c < :callEndDateTime
            AND Offered_Call__c = 1
            AND NVMStatsSF__CLID__c != 'Anonymous'
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<NVMStatsSF__NVM_Call_Summary__c> scope) {
        Map<String, Customer_Inquiry__c> existingCLIDtoInquiryMap = new Map<String, Customer_Inquiry__c>();
        Map<String, Customer_Inquiry__c> newCLIDtoInquiryMap = new Map<String, Customer_Inquiry__c>();
        List<Customer_Inquiry__c> lstCustomerInquiryNew = new List<Customer_Inquiry__c>();
        Set<Id> setExisting = new Set<Id>();
         List<Customer_Inquiry__c> lstCustomerInquiryExisting = new List<Customer_Inquiry__c>();
        // Pull a List of open Customer Inquiries
        List<Customer_Inquiry__c> lstCustomerInquiryOpen = [SELECT Id, CLID__c, Last_Call_DateTime__c, Call_Count__c
                                                            FROM Customer_Inquiry__c
                                                            WHERE Closed__c = false];
        
        // Create a map of existing CLID to Customer Inquiry of the List
        for(Customer_Inquiry__c inquiry : lstCustomerInquiryOpen) {
            existingCLIDtoInquiryMap.put(inquiry.CLID__c, inquiry);
        }
        
        // Iterate through the Call Summaries
        for (NVMStatsSF__NVM_Call_Summary__c callSummary : scope) {
            String clid = callSummary.NVMStatsSF__CLID__c;
            DateTime callDateTime = callSummary.NVMStatsSF__CallTime__c;
            
            if (existingCLIDtoInquiryMap.containsKey(clid)) {
                Customer_Inquiry__c inquiry = existingCLIDtoInquiryMap.get(clid);
                inquiry.Last_Call_DateTime__c = callDateTime;
                inquiry.Call_Count__c += 1;
                callSummary.Customer_Inquiry__c = inquiry.Id;
                if(setExisting.add(inquiry.Id)) {
                    lstCustomerInquiryExisting.add(inquiry);
                }
            } else if (newCLIDtoInquiryMap.containsKey(clid)) {
                Customer_Inquiry__c inquiry = newCLIDtoInquiryMap.get(clid);
                inquiry.Last_Call_DateTime__c = callDateTime;
                inquiry.Call_Count__c += 1;
                callSummary.Customer_Inquiry__c = inquiry.Id;
            } else {
                Customer_Inquiry__c newInquiry = new Customer_Inquiry__c(
                    CLID__c = clid,
                    Customer__c = callSummary.NVMStatsSF__Related_Contact__c,
                    First_Call_Summary__c = callSummary.Id,
                    First_Call_DateTime__c = callDateTime,
                    Last_Call_DateTime__c = callDateTime,
                    Call_Count__c = 1
                );
                lstCustomerInquiryNew.add(newInquiry);
                newCLIDtoInquiryMap.put(clid, newInquiry);
            }
        }
        
        
        // Insert new Customer Inquiries
        Database.insert(lstCustomerInquiryNew,false);
        
        //Update exsiting Customer Inquiries
        Database.update(lstCustomerInquiryExisting,false);
        
        // Loop through the Call Summaries again to update Customer_Inquiry__c field
        for(NVMStatsSF__NVM_Call_Summary__c callSummary : scope) {
            String clid = callSummary.NVMStatsSF__CLID__c;
            if(newCLIDtoInquiryMap.containsKey(clid)) {
                callSummary.Customer_Inquiry__c = newCLIDtoInquiryMap.get(clid).Id;
            }
        }
        
        // Update Call Summaries with Customer_Inquiry__c field
        update scope;
    }
    
    public void finish(Database.BatchableContext context) 
    {      
        Database.executeBatch(new BatchCloseCustomerInquiries(this.callEndDateTime));
    }
}