@isTest
public class EmailMessageHandlerTest {
    
    @isTest
    public static void testScanEmailSubject(){
        Account corporateAC = new Account(name = 'Affordable Care', location_ID__c = '');
        insert corporateAC;

        Account practiceAC = new Account(name = 'Asheville-North Carolina', location_ID__c = '1001');
        insert practiceAC;

        List<Id> emailIds = new List<Id>();
        Id aceId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ACE Service').getRecordTypeId();
        List<EmailMessage> lstEmailMsg = new List<EmailMessage>();
        List<Id> emailMsgId = new List<Id>();
        String[] strLocation;
        Set<String> locationIds = new Set<String>();
        String locationIdFromSet;
        Map<String,Account> mapLocation = new Map<String,Account>();        
        List<Case> lstCases = new List<Case>(); 
        Set<Id> caseIds = new Set<Id>();
        Map<Id,Case> mapCases = new Map<Id,Case>();
        Case updatedCase = new Case();
        Database.DMLOptions dmlOpts = new Database.DMLOptions();

        //Purchasing case      
        Case c = new Case();
        c.AccountId = corporateAC.Id;
        c.recordtypeid = aceId;
        c.Team__c = 'Severadent Purchasing';
        c.Category__c = 'Other';
        c.Subcategory__c = 'Other';
        c.Location_Found__c = false;
        c.Origin = 'Email';
        insert c;
        caseIds.add(c.Id);
        
        //Customer's reply email for Purchasing case with location id in subject
        EmailMessage em = new EmailMessage();
        em.ParentId = c.Id;
        em.incoming = true;
        em.subject = 'Test Purchasing case loc 1001';
        insert em;
        emailMsgId.add(em.Id);
        
        lstEmailMsg = EmailMessageHandler.getEmailList(emailMsgId);
        System.assertEquals(1, lstEmailMsg.size());
        
        strLocation = EmailMessageHandler.getLocationFromSubject(em.Subject);
        System.assertEquals('1001', strLocation[0]);
        
        locationids = EmailMessageHandler.getLocationIdSet(strLocation);
        locationIdFromSet = ((new list<String>(locationIds))[0]);
        System.assertEquals('01001', locationIdFromSet);
        
        mapLocation = EmailMessageHandler.setMapLocationToAccount(locationIds);
        System.assertEquals(practiceAC.id, mapLocation.get(locationIdFromSet).id);        
        
        dmlOpts = EmailMessageHandler.setAssignmentRule(dmlOpts);
        
        lstCases = EmailMessageHandler.getCasesFromEmailMessage(caseIds);
        System.assertEquals(c.Id, lstCases[0].id);
        
        mapCases = EmailMessageHandler.setMapWithCases(lstCases);
        System.assert(mapCases.containsKey(c.Id)); 
        
        updatedCase = EmailMessageHandler.setCasePracticeAndOwner(em,locationids,mapCases,mapLocation,dmlOpts); 
        System.assertEquals(practiceAC.Id, updatedCase.Accountid);
        
        lstCases.add(updatedCase);        
        EmailMessageHandler.updateCases(lstCases,dmlOpts);
        System.assertEquals(true, lstCases[0].Location_found__c);
        
        Case c1 = new Case();
        c1.AccountId = corporateAC.Id;
        c1.recordtypeid = aceId;
        c1.Team__c = 'Severadent Purchasing';
        c1.Category__c = 'Other';
        c1.Subcategory__c = 'Other';
        c1.Location_Found__c = false;
        c1.Origin = 'Email';
        insert c1;
        
        //Customer's reply email for Purchasing case without location id in subject
        em = new EmailMessage();
        em.ParentId = c1.Id;
        em.incoming = true; 
        em.subject = 'Test Purchasing case 1 '; 
        insert em;

        emailIds.add(em.Id);
        EmailMessageHandler.scanEmailSubject(emailIds);
        
        c1 = [Select Id, Location_found__c, AccountId from case where id = :c1.id];
        System.assertEquals(false,c1.Location_found__c);
    }
}