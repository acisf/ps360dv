/*
 * Create call center summaries; ie, sums of kpi raw data for the day
 * 
*/

global class BatchCallCenterSummary implements Database.Batchable<sObject>, Database.Stateful {
    public Date summaryDate;
    
    global BatchCallCenterSummary(Date summaryDate) {
        this.summaryDate = summaryDate;
    }
    
    //get names from KPI metadata 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (Test.isRunningTest()) {
            return Database.getQueryLocator([SELECT DeveloperName FROM KPI__mdt LIMIT 1]);
        }
        return Database.getQueryLocator([SELECT DeveloperName FROM KPI__mdt]);
    }
    
    
    global void execute(Database.BatchableContext bc, List<KPI__mdt> scope) {
        
        for (KPI__mdt k : scope) { 
            
            String kpiName = k.DeveloperName; 
            
            Decimal value = runAggregateQuery(kpiName);
            
            if (value == null) 
                value = 0;
         
            
            // Find or create the summary record for the given date
            Call_Center_Summary__c summaryRecord;
            List<Call_Center_Summary__c> existing = [
                SELECT Id, KPI_Date__c,Company__c,
                TotalAbandoned__c, TotalAnswered__c, TotalAnsweredInSVL__c, TotalAnswerTime__c,
                TotalAppointments__c, TotalClosed__c, TotalDispositionCount__c, TotalInbound__c,
                TotalOffered__c, TotalQuestion1__c, TotalResolved__c, TotalScheduledCount__c,
                TotalSurveys__c, TotalTransfers__c
                FROM Call_Center_Summary__c
                WHERE KPI_Date__c = :summaryDate
                LIMIT 1
            ];
            
            if (!existing.isEmpty()) {
                summaryRecord = existing[0];
            } else {
                summaryRecord = new Call_Center_Summary__c(KPI_Date__c = summaryDate,Company__c='All');
            }
            
            summaryRecord = setSummaryValue(summaryRecord,kpiName,value);
            
            if (summaryRecord.Id != null) {
                update summaryRecord;
            } else {
                insert summaryRecord;
                System.debug('Inserted summary record for: ' + summaryDate);
            }
        }
    }
    
    public Call_Center_Summary__c setSummaryValue(Call_Center_Summary__c sr, String kpiName, Decimal value) {
           // Set the appropriate field based on the KPI name
            if (kpiName == 'TotalAbandoned') sr.TotalAbandoned__c = Integer.valueOf(value);
            else if (kpiName == 'TotalAnswered') sr.TotalAnswered__c = Integer.valueOf(value);
            else if (kpiName == 'TotalAnsweredInSVL') sr.TotalAnsweredInSVL__c = Integer.valueOf(value);
            else if (kpiName == 'TotalAnswerTime') sr.TotalAnswerTime__c = value;
            else if (kpiName == 'TotalAppointments') sr.TotalAppointments__c = Integer.valueOf(value);
            else if (kpiName == 'TotalClosed') sr.TotalClosed__c = Integer.valueOf(value);
            else if (kpiName == 'TotalDispositionCount') sr.TotalDispositionCount__c = Integer.valueOf(value);
            else if (kpiName == 'TotalInbound') sr.TotalInbound__c = Integer.valueOf(value);
            else if (kpiName == 'TotalOffered') sr.TotalOffered__c = Integer.valueOf(value);
            else if (kpiName == 'TotalQuestion1') sr.TotalQuestion1__c = value;
            else if (kpiName == 'TotalResolved') sr.TotalResolved__c = Integer.valueOf(value);
            else if (kpiName == 'TotalScheduledCount') sr.TotalScheduledCount__c = Integer.valueOf(value);
            else if (kpiName == 'TotalSurveys') sr.TotalSurveys__c = Integer.valueOf(value);
           else if (kpiName == 'TotalTransfers') sr.TotalTransfers__c = Integer.valueOf(value);
        return sr;
    }
    
    public Decimal runAggregateQuery(String kpiName) {
        DateTime dtStart = DateTime.newInstance(summaryDate, Time.newInstance(0, 0, 0, 0));
        DateTime dtEnd = DateTime.newInstance(summaryDate.addDays(1), Time.newInstance(0, 0, 0, 0));
        
        //System.debug('KPI: ' + kpiName);
        //System.debug('Start: ' + dtStart);
        //System.debug('End: ' + dtEnd);
        
        if(kpiName == 'TotalAbandoned') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
                AND Offered_Call__c = 1
                AND Abandoned_in_Queue__c = 1 
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if (kpiName == 'TotalAnswered') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
                AND Offered_Call__c = 1
                AND Answered_Call__c = 1
            ];
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if(kpiName == 'TotalAnswerTime') {
            AggregateResult[] results = [
                SELECT SUM(Answer_Time__c) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
                AND Offered_Call__c = 1 
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if(kpiName == 'TotalAnsweredInSVL') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
                AND Offered_Call__c = 1
                AND Answered_in_SVL__c = 1
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        } 
        else if (kpiName == 'TotalAppointments') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
                AND NVMStatsSF__CallDisposition__c IN ('Scheduled', 'OB - Scheduled')
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if (kpiName == 'TotalClosed') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM Customer_Inquiry__c
                WHERE Date_Time_Closed__c >= :dtStart AND Date_Time_Closed__c < :dtEnd
                
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if (kpiName == 'TotalResolved') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM Customer_Inquiry__c
                WHERE Date_Time_Closed__c >= :dtStart AND Date_Time_Closed__c < :dtEnd
                AND Resolved_on_First_Call__c = 1
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if (kpiName == 'TotalDispositionCount') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c  >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
                AND NVMStatsSF__CallDisposition__c IN ('Fees/Services', 'Scheduled')
                AND NVMStatsSF__Interaction_Type__c = 'Inbound Call'
                
            ];            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if (kpiName == 'TotalInbound') {
            AggregateResult[] results = [
                SELECT SUM(NVMStatsSF__Number_of_Inbound_Calls_FORMULA__c) total
                FROM NVMStatsSF__NVM_Agent_Summary__c
                WHERE CreatedDate >= :dtStart AND CreatedDate < :dtEnd
                
            ];            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if(kpiName == 'TotalOffered') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
                AND Offered_Call__c = 1
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if(kpiName == 'TotalQuestion1') {
            AggregateResult[] results;
            
            if(summaryDate < Date.newInstance(2025,3,1)) {
                   results = [
                SELECT SUM(Answer_1__c) total
                FROM NVM_PCS__c
                WHERE CreatedDate >= :dtStart AND CreatedDate <:dtEnd ];
                //AND Vonage_Call_Summary__c != null];
            } else {
            results = [
                SELECT SUM(Question_1__c) total
                FROM OAI_Survey__c
                WHERE CreatedDate >= :dtStart AND CreatedDate <:dtEnd 
                AND Vonage_Call_Summary__c != null
            ];
            }
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        
        else if(kpiName == 'TotalSurveys') {
            
            AggregateResult[] results;
            
            //3/1/2025 - changed survey vendor
			//9/1/2024 - updated nvm_pcs to include lookup to call summary
            
             if(summaryDate < Date.newInstance(2025,3,1)) {   
                  results = [
                SELECT COUNT(Id) total
                FROM NVM_PCS__c
                WHERE CreatedDate >= :dtStart AND CreatedDate <:dtEnd];
                //AND Vonage_Call_Summary__c != null];
             } else {
                 
                  results = [
                SELECT COUNT(Id) total
                FROM OAI_Survey__c
                WHERE CreatedDate >= :dtStart AND CreatedDate <:dtEnd 
                AND Vonage_Call_Summary__c != null];
             }
            
             if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
       
        }
        else if(kpiName == 'TotalScheduledCount') {
            AggregateResult[] results = [
                SELECT COUNT(Id) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
                AND NVMStatsSF__CallDisposition__c = 'Scheduled'
                AND NVMStatsSF__Interaction_Type__c = 'Inbound Call'                
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        else if(kpiName == 'TotalTransfers') {
            AggregateResult[] results = [
                SELECT SUM(NVMStatsSF__Number_of_Transfers__c) total
                FROM NVMStatsSF__NVM_Call_Summary__c
                WHERE NVMStatsSF__CallTime__c >= :dtStart AND NVMStatsSF__CallTime__c < :dtEnd
            ];
            
            if(results[0].get('total') == null)
                return 0;
            else            
                return (Decimal)results[0].get('total');
        }
        
        
        return null;
    }
    
    global void finish(Database.BatchableContext bc) {
        //chain batch jobs from 1/1/2024 - 12/29/2024
        Date endDate = Date.newInstance(2024,12,30);
        if(summaryDate < endDate) {
             Date nextDate = summaryDate.addDays(1);
             BatchCallCenterSummary batch = new BatchCallCenterSummary(nextDate);
             ID batchId = Database.executeBatch(batch, 1);
        }
        
    }
    
}