@isTest
private class UPSDeliveryEmailHandlerTest {

    @testSetup
    static void setup() {
        // Must match the tracking number used in test methods exactly
        insert new Case(
            Subject = 'Test Case', 
            Tracking_Number__c = '1ZE214E09095360682',
            Status = 'New'
        );
    }

    @isTest
    static void testDeliveryUpdate() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        // Tracking number in subject matches the Case created in setup
        email.subject = 'UPS Delivery Notification, Tracking Number 1ZE214E09095360682';
        email.plainTextBody = 'Package delivered at 1:43 PM.';

        UPSDeliveryEmailHandler handler = new UPSDeliveryEmailHandler();
        
        Test.startTest();
        handler.handleInboundEmail(email, new Messaging.InboundEnvelope());
        Test.stopTest();

        Case c = [SELECT Shipping_Status__c FROM Case WHERE Tracking_Number__c = '1ZE214E09095360682' LIMIT 1];
        System.assertEquals('Delivered', c.Shipping_Status__c, 'Status update failed.');
    }

    @isTest
    static void testOrphanEmail() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'UPS Ship Notification, Tracking Number 1Z0000000000000000';
        email.plainTextBody = 'No matching case for this.';

        UPSDeliveryEmailHandler handler = new UPSDeliveryEmailHandler();
        handler.handleInboundEmail(email, new Messaging.InboundEnvelope());

        List<Task> tasks = [SELECT Subject FROM Task WHERE Subject LIKE '%1Z0000000000000000%'];
        System.assertEquals(1, tasks.size(), 'Orphan task not created.');
    }
}