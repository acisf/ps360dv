@isTest
public class UpdateChildCasesTest {

    @isTest
    public static void testChildCases(){
        Id aceserviceId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ACE Service').getRecordTypeId(); 
        List<Id> parent_id = new List<Id>();
        
        Case parent = new Case();
        parent.RecordTypeId = aceserviceId;
        parent.Subject = 'Parent Case';
        parent.Description = 'Parent Case';
        parent.Team__c = 'IT';
        parent.Category__c = 'Enterprise Applications';
        parent.Subcategory__c = 'Salesforce';
        parent.Origin = 'Phone';
        parent.Status ='Open';        
        insert parent;
        parent_id.add(parent.id);
        
        Case child = new Case();
        child.RecordTypeId = aceserviceId;
        child.Subject = 'Parent Case';
        child.Description = 'Parent Case';
        child.Team__c = 'IT';
        child.Category__c = 'Enterprise Applications';
        child.Subcategory__c = 'Salesforce';
        child.Origin = 'Phone';
        child.ParentId = parent.id;
        insert child;
        
        Test.startTest();
        UpdateChildCases.updateChildCasesStatus(parent_id);
        Test.stopTest();
        
        Case c = [Select Id,Status from Case where id = :child.id limit 1];
        System.assertEquals(c.Status, 'Open');
        
    }
}