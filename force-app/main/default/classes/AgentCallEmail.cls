public class AgentCallEmail {
    
    public static Date dt = Date.today() -1;
    public static Time tm = Time.newInstance(0,0,0,0);
    public static DateTime calldatetime = DateTime.newInstance(dt, tm ); 
    
    public static void run() {
        
        Set<id> agents = new Set<id>();
        Set<id> summaries = new Set<id>();
        Set<id> contacts  = new Set<id>();
        Map<id,NVMStatsSF__NVM_Agent_Summary__c> summarymap = new map<id,NVMStatsSF__NVM_Agent_Summary__c>();
        List<NVMStatsSF__NVM_Call_Summary__c> lstScheduled; 
        List<NVMStatsSF__NVM_Agent_Summary__c> lstAgentSummaries;
        
        lstAgentSummaries = [SELECT id, NVMStatsSF__Agent__c,
                             Unique_New_Patient_Appointments__c,
                             Unique_New_Patient_Email_Captured__c,
                             Unique_Prospect_Email_Captured__c  ,
                             Scheduled_Appts__c,
                             Number_of_Fees_Services_Calls__c,
                             Consult_Time__c	,
                             After_Call_Work_Time__c                      
                             FROM NVMStatsSF__NVM_Agent_Summary__c
                             WHERE NVMStatsSF__Date__c =: dt];
        
        system.debug(lstAgentSummaries);
        
        for(NVMStatsSF__NVM_Agent_Summary__c summary: lstAgentSummaries) {   
            summaries.add(summary.id);
            summarymap.put(summary.NVMStatsSF__Agent__c,summary);
        }
        
        //patient appts
        lstScheduled = [SELECT Id, NVMStatsSF__Related_Contact__c
                        FROM NVMStatsSF__NVM_Call_Summary__c
                        WHERE NVMStatsSF__Last_Agent_Summary__c in: summaries
                        AND NVMStatsSF__CallDisposition__c =: 'Scheduled'];
        
        //set of those contacts
        for(NVMStatsSF__NVM_Call_Summary__c call: lstScheduled) {
            contacts.add(call.NVMStatsSF__Related_Contact__c);
        }
        
        //calls where those contacts have scheduled in the past
        lstScheduled = [SELECT Id, NVMStatsSF__Related_Contact__c
                        FROM NVMStatsSF__NVM_Call_Summary__c
                        WHERE NVMStatsSF__CallDisposition__c =: 'Scheduled' 
                        AND NVMStatsSF__Related_Contact__c in:contacts
                        AND NVMStatsSF__CallTime__c <: (calldatetime)];
        
        //remove those from the set
        for(NVMStatsSF__NVM_Call_Summary__c call: lstScheduled) {
            contacts.remove(call.NVMStatsSF__Related_Contact__c);
        }
        
        //count of appts
        AggregateResult[] apptResults = [SELECT  NVMStatsSF__Agent__c ,
        Count_distinct(Id) appts
        FROM NVMStatsSF__NVM_Call_Summary__c
        WHERE NVMStatsSF__Last_Agent_Summary__c in: summaries
        AND ( NVMStatsSF__CallDisposition__c =: 'Scheduled'
        OR NVMStatsSF__CallDisposition__c =: 'OB - Scheduled' )
        GROUP BY NVMStatsSF__Agent__c ];

        //count of fees and services
        AggregateResult[] feesResults = [SELECT  NVMStatsSF__Agent__c ,
        Count_distinct(Id) fscalls
        FROM NVMStatsSF__NVM_Call_Summary__c
        WHERE NVMStatsSF__Last_Agent_Summary__c in: summaries
        AND ( NVMStatsSF__CallDisposition__c =: 'Fees/Services')
        GROUP BY NVMStatsSF__Agent__c ];

        //summaries for the psr daily details report
        AggregateResult[] detResults = [SELECT  NVMStatsSF__Agent__c ,
        SUM(NVMStatsSF__After_Call_Work_Time__c ) afterCallWorkTime,
        SUM(NVMStatsSF__Agent_Consult_Time__c ) consultTime
        FROM NVMStatsSF__NVM_Call_Summary__c
        WHERE NVMStatsSF__Last_Agent_Summary__c in: summaries
        GROUP BY NVMStatsSF__Agent__c ];

        //count of unique new patient appts and unique new patient appt emails by agent
        AggregateResult[] patientResults = [SELECT  NVMStatsSF__Agent__c ,
                                            Count_distinct(Id) UniqueNewPatientAppts, 
                                            Count_distinct(NVMStatsSF__Related_Contact__r.Email) Email
                                            FROM NVMStatsSF__NVM_Call_Summary__c
                                            WHERE NVMStatsSF__Last_Agent_Summary__c in: summaries
                                            AND NVMStatsSF__Related_Contact__c IN: contacts
                                            GROUP BY NVMStatsSF__Agent__c ];
        
        
        //prospects, emails by agent
        AggregateResult[] prospectResults = [SELECT  NVMStatsSF__Agent__c ,
                                             Count_distinct(Id) UniqueProspectCalls, 
                                             Count_distinct(NVMStatsSF__Related_Contact__r.Email) Email
                                             FROM NVMStatsSF__NVM_Call_Summary__c
                                             WHERE NVMStatsSF__Last_Agent_Summary__c in: summaries
                                             AND NVMStatsSF__CallDisposition__c =: 'Fees/Services'
                                             GROUP BY NVMStatsSF__Agent__c ];  
        
        system.debug(prospectResults);
        
        //update agent summaries
        for (AggregateResult ar : apptResults)  {
            Id agentid = (Id)ar.get('NVMStatsSF__Agent__c'); 
            if(summarymap.get(agentid)!=null) {
                summarymap.get(agentid).Scheduled_Appts__c =(double)ar.get('appts');              
            }         
        }

        for (AggregateResult fs : feesResults)  {
            Id agentid = (Id)fs.get('NVMStatsSF__Agent__c'); 
            if(summarymap.get(agentid)!=null) {
                summarymap.get(agentid).Number_of_Fees_Services_Calls__c = (double)fs.get('fscalls');        //add field      
            }         
        }


        for (AggregateResult ar : detResults)  {
            Id agentid = (Id)ar.get('NVMStatsSF__Agent__c'); 
            if(summarymap.get(agentid)!=null) {
                summarymap.get(agentid).After_Call_Work_Time__c =(double)ar.get('afterCallWorkTime');
                summarymap.get(agentid).Consult_Time__c =(double)ar.get('consultTime');        
            }         
        }       
        
        
        for (AggregateResult ar : prospectResults)  {
            Id agentid = (Id)ar.get('NVMStatsSF__Agent__c'); 
            if(summarymap.get(agentid)!=null) {
                summarymap.get(agentid).Unique_Prospect_Fees_Services_Calls__c =(double)ar.get('UniqueProspectCalls');
                summarymap.get(agentid).Unique_Prospect_Email_Captured__c =(double)ar.get('Email');
            }         
        }
        
        for (AggregateResult ar : patientResults)  {
            Id agentid = (Id)ar.get('NVMStatsSF__Agent__c'); 
            if(summarymap.get(agentid)!=null) {
                summarymap.get(agentid).Unique_New_Patient_Appointments__c =(double)ar.get('UniqueNewPatientAppts');
                summarymap.get(agentid).Unique_New_Patient_Email_Captured__c =(double)ar.get('Email');
            } 
        }
        
        update summarymap.values();
        
    }
}