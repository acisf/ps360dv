global class ScheduleAgentCallEmail implements Schedulable {
/*
 //System.schedule('Agent Summaries Email Capture','0 3 0 1/1 * ? *', new ScheduleAgentCallEmail());
*/
    
 global void execute(SchedulableContext SC) { 
        AgentCallEmail.run(); 
    }
}