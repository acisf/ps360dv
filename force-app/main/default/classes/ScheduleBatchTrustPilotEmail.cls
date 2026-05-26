global class ScheduleBatchTrustPilotEmail implements Schedulable { 
    // 0 11 13 1,15 * ? *
    // System.schedule('TrustPilot Email','0 0 13 1,2,15,16 * ? *',new ScheduleBatchTrustPilotEmail());
        global void execute(SchedulableContext SC) { 
          Database.executeBatch(new TrustPilotEmail(),25);
        }
    }