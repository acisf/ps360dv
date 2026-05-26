@isTest
public class CloseRepairsCaseTest {
    public static Account acc;
    public static Contact con;
    
    @isTest 
    public static void testData(){
        acc = new Account(Name='Test Account');
        insert acc;
        
        con = new Contact(FirstName='John',LastName='Doe',Email='John.Doe@affordablecare.com',AccountId=acc.Id);
        insert con;
    }

    @isTest
    public static void testRepairsCasewithWorkOrder(){
        testData();
        
        Case repairCase = new Case();
        repairCase.AccountId = acc.Id;
        repairCase.ContactId = con.Id;
        repairCase.Team__c = 'Dental Equipment Repairs';
        repairCase.Category__c = 'Large Equipment';
        repairCase.Subject = 'Large Equipment |';
        repairCase.Description = 'autoclave not operating properly. Cant sterilize instruments';
        repairCase.Origin = 'Phone';
        insert repairCase;
        
        EmailMessage em = new EmailMessage();
        em.parentId = repairCase.Id;
        em.Subject= 'Re: Equipment repair request';
        em.HtmlBody = 'Good morning! Thank you for choosing Henry Schein Service First.'+
            		  ' Our technician Alexander will be out to the office on Friday August 20th using work order SR21081900215.';
        em.Incoming = true;
        em.FromAddress = 'madhuri.nandula@henryschein.com';
        insert em;
        
        CloseRepairsCase.autoCloseRepairsCase();
        
        Case updatedRepairCase = [Select status from case where id = :repairCase.id limit 1];
        FeedItem feed = [Select id from FeedItem where parentId = :repairCase.id limit 1];
        System.assertEquals(updatedRepairCase.Status, 'Resolved');
        System.assert(feed != null);
        
        
    }
    @isTest
    public static void testRepairsCaseNoWorkOrder(){
        testData();
        DateTime dt = DateTime.now();
        
        Case repairCaseSmallEquipment = new Case();
        repairCaseSmallEquipment.AccountId = acc.Id;
        repairCaseSmallEquipment.ContactId = con.Id;
        repairCaseSmallEquipment.Team__c = 'Dental Equipment Repairs';
        repairCaseSmallEquipment.Category__c = 'Small Equipment / Handpiece';
        repairCaseSmallEquipment.Subject = 'Small Equipment / Handpiece |';
        repairCaseSmallEquipment.Description = 'Two handpieces are not operating properly. One handpiece sprays water everywhere, and the other does not hold the bur.';
        repairCaseSmallEquipment.Origin = 'Phone';
        repairCaseSmallEquipment.CreatedDate = dt.addDays(-10);
        insert repairCaseSmallEquipment;
        
        EmailMessage em = new EmailMessage();
        em.parentId = repairCaseSmallEquipment.Id;
        em.Subject= 'Re: Equipment repair request';
        em.HtmlBody = 'Adding ProRepair in- please see the below request, their account is JDE 1378833';            		 
        em.Incoming = true;
        em.FromAddress = 'madhuri.nandula@henryschein.com';        
        insert em;
        
        CloseRepairsCase.autoCloseRepairsCase();
        
        Case updatedRepairCase = [Select status from case where id = :repairCaseSmallEquipment.id limit 1];
        List<FeedItem> feed = [Select id from FeedItem where parentId = :repairCaseSmallEquipment.id];
        System.assertEquals(updatedRepairCase.Status, 'Resolved');
        System.assert(feed.size() == 0);
        
        
    }
    
    @isTest
    public static void testRepairsCaseNoEmailReply(){
        testData();
        DateTime dt = DateTime.now();
        
        Case repairCaseSmallEquipment = new Case();
        repairCaseSmallEquipment.AccountId = acc.Id;
        repairCaseSmallEquipment.ContactId = con.Id;
        repairCaseSmallEquipment.Team__c = 'Dental Equipment Repairs';
        repairCaseSmallEquipment.Category__c = 'Small Equipment / Handpiece';
        repairCaseSmallEquipment.Subject = 'Small Equipment / Handpiece |';
        repairCaseSmallEquipment.Description = 'Two handpieces are not operating properly. One handpiece sprays water everywhere, and the other does not hold the bur.';
        repairCaseSmallEquipment.Origin = 'Phone';
        repairCaseSmallEquipment.CreatedDate = dt.addDays(-10);
        insert repairCaseSmallEquipment;   
        
        CloseRepairsCase.autoCloseRepairsCase();
        
        Case updatedRepairCase = [Select status from case where id = :repairCaseSmallEquipment.id limit 1];
        List<FeedItem> feed = [Select id from FeedItem where parentId = :repairCaseSmallEquipment.id];
        System.assertNotEquals(updatedRepairCase.Status, 'Resolved');
        System.assert(feed.size() == 0);
        
        
    }
    
    @isTest
    public static void testNoRepairsCase(){
        testData();
        DateTime dt = DateTime.now();
        
        Case ITCase = new Case();
        ITCase.AccountId = acc.Id;
        ITCase.ContactId = con.Id;
        ITCase.Team__c = 'IT';
        ITCase.Category__c = 'Enterprise Applications';
        ITCase.Subcategory__c = 'Salesforce';
        ITCase.Subject = 'Salesforce login issue';
        ITCase.Description = 'Salesforce login issue';
        ITCase.Origin = 'Phone';
        ITCase.CreatedDate = dt.addDays(-10);
        insert ITCase;   
        
        CloseRepairsCase.autoCloseRepairsCase();
        
        Case caseData = [Select status from case where id = :ITCase.id limit 1];       
        System.assertNotEquals(caseData.Status, 'Resolved');      
        
    }
}