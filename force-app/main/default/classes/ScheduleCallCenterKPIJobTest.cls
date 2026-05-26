@isTest
private class ScheduleCallCenterKPIJobTest {

    @isTest
    static void testJobIsScheduled() {
        Test.startTest();
        String jobId = System.schedule(
            'Test KPI Schedule',
            '0 0 6 ? * SUN', // 6 AM every Sunday
            new ScheduleCallCenterKPIJob()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
    }
}