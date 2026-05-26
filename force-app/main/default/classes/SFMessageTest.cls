@isTest
private class SFMessageTest {
    @IsTest
    private static void doTest(){
        SFMessage m = new SFMessage();
        m.setMessage('SFMessage', 'error');
        System.assertEquals(m.message, 'SFMessage');
        System.assertEquals(m.severity, 'error');

    }
}