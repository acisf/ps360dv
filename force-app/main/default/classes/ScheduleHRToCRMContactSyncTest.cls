@IsTest
public class ScheduleHRToCRMContactSyncTest {

    @IsTest
    static void testSchedulerIsCreated() {

        // Cron: run once in the future
        String cronExp = '0 0 0 1 1 ? 2099';

        Test.startTest();

        String jobId = System.schedule(
            'Test HR → CRM Contact Sync',
            cronExp,
            new ScheduleHRToCRMContactSync()
        );

        Test.stopTest();

        // Verify the job was scheduled
        CronTrigger ct = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
    }
}