@isTest
public class SchedulingRequirementsTriggerHandlerTest {

    @isTest
    static void testPlainTextConversion() {
        // Arrange: Create a mock record with rich text
        Scheduling_Requirements__c sr = new Scheduling_Requirements__c(
            Scheduling_Requirement_Note__c = '<p>This is <b>bold</b> &amp; <i>italic</i>.</p>'
        );

        List<Scheduling_Requirements__c> mockList = new List<Scheduling_Requirements__c> { sr };

        // Act: Call the handler directly
        SchedulingRequirementsTriggerHandler.handle(mockList);
        
        System.debug(sr.Scheduling_Requirement_PlainText__c);

        // Assert: Check the transformation
        System.assertNotEquals(null, sr.Scheduling_Requirement_PlainText__c, 'Plain text should not be null');
        System.assert(sr.Scheduling_Requirement_PlainText__c.contains('This is'), 'Plain text should contain visible content');
        System.assert(!sr.Scheduling_Requirement_PlainText__c.contains('<'), 'Plain text should not contain HTML tags');
        System.assert(sr.Scheduling_Requirement_PlainText__c.contains('&') == true, 'HTML entities should be decoded');
    }

    @isTest
    static void testNoNoteProvided() {
        // Arrange: Record with null note
        Scheduling_Requirements__c sr = new Scheduling_Requirements__c( 
        );

        List<Scheduling_Requirements__c> mockList = new List<Scheduling_Requirements__c> { sr };

        // Act
        SchedulingRequirementsTriggerHandler.handle(mockList);

        // Assert
        System.assertEquals(null, sr.Scheduling_Requirement_PlainText__c, 'Plain text should remain null when no input');
    }
    
    @isTest
    static void testInsert() {
   
        Account a = new Account();
        a.Name = 'Asheville';
        a.Location_Id__c = '01001';
        insert a;
        Scheduling_Requirements__c sr = new Scheduling_Requirements__c();
        sr.Scheduling_Requirement_Note__c = 'Practice offers free consultation';
        sr.Practice__c = a.id;
        sr.Scheduling_Requirement_Type__c = 'Consult';        
        insert sr;
    }
}