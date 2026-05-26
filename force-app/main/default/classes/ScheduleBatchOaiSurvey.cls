global class ScheduleBatchOaiSurvey implements Schedulable {
    global void execute(SchedulableContext SC) {
        System.debug('Executing Scheduled Batch Job for OAI Survey...');
        Database.executeBatch(new BatchOaiSurvey(), 200);
    }
}