@isTest
private class ScheduleBatchNoShowTest {
    @isTest
    static void testSchedule() {
        Test.startTest();
        
        ScheduleBatchNoShow sched = new ScheduleBatchNoShow();
        String cronExp = '0 0 6 * * ?';
        String jobId = System.schedule('Test Daily BatchNoShow Job', cronExp, sched);    
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'JobId should not be null when scheduling succeeds.');
    }
}