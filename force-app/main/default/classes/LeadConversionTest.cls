@isTest
public class LeadConversionTest {

    @isTest
    public static void testAutoLeadConversion() {
        Lead l = new Lead();
        List<Lead> lstLeads = new List<Lead>();
        List<Id> leadIds = new List<Id>();
        Map<String,Id> mapLeadCompany = new Map<String,Id>();
        Map<Id,Id> mapLeadPractice = new Map<Id,Id>();
        Map<Id,String> mapLeadOwner = new Map<Id,String>();
        Id affiliationRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliations').getRecordTypeId();
        Id affiliationConRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Affiliations').getRecordTypeId();
        Database.LeadConvert leadConvert;
        List<Database.LeadConvert> lstLeadConvert = new List<Database.LeadConvert>();
        LeadStatus leadStatus = new LeadStatus();        
        List<Database.LeadConvertResult> lstLeadConvertResult = new List<Database.LeadConvertResult>();

        Account affiliateAC = new Account();
        affiliateAC.Name = 'Doe Family Dentistry';
        affiliateAC.recordtypeid = affiliationRT;
        insert affiliateAC;

        l.FirstName = 'John';
        l.LastName = 'Doe';
        l.Email = 'john.doe@example.com';
        l.company = 'Doe Family Dentistry';
        l.status = 'New Lead';
        l.ownerId = '00536000002R3OY';
        lstLeads.add(l);

        l = new Lead();
        l.FirstName = 'Jack';
        l.LastName = 'Daniel';
        l.Email = 'jack.daniel@example.com';
        l.company = 'All Smiles Dentistry';
        l.status = 'New Lead';
        l.ownerId = '00G1R000003KGxo';
        lstLeads.add(l);

        insert lstLeads;      

        for(Lead ld: lstLeads)
            leadIds.add(ld.Id);

        mapLeadOwner = LeadConversion.getLeadOwnerThatIsNotQueue(leadIds);
            
        mapLeadCompany = LeadConversion.getCompanyFromLead(leadIds);  
        System.assertEquals(2,mapLeadCompany.size());   
        
        mapLeadPractice = LeadConversion.findExistingPracticeFromCompany(affiliationRT,mapLeadCompany);
        System.assertEquals(1,mapLeadPractice.size());

        for(Id leadId: leadIds){
            leadConvert = new Database.LeadConvert();
            leadConvert = LeadConversion.setLeadConversionStatus(leadConvert,leadId,leadStatus,mapLeadPractice, mapLeadOwner);
            lstLeadConvert.add(leadConvert);
        } 
        System.assertEquals(2,lstLeadConvert.size());

        lstLeadConvertResult = LeadConversion.convertLead(lstLeadConvert);
        System.assertEquals(2,lstLeadConvertResult.size());

        lstLeads = new List<Lead>();
        l = new Lead();
        l.FirstName = 'Sansa';
        l.LastName = 'Stark';
        l.Email = 'sansa.stark@example.com';
        l.company = 'Stark Family Dentistry';
        l.status = 'New Lead';
        lstLeads.add(l);

        insert lstLeads;  
        
        leadIds = new List<Id>();
        for(Lead ld: lstLeads)
            leadIds.add(ld.Id);

        LeadConversion.autoConvertLead(leadIds);
        Account ac = [Select id, recordtypeid from Account where name = :l.company];
        Contact con = [Select id, recordtypeid from Contact where FirstName = :l.FirstName and LastName = :l.LastName];
        Lead convertedLead = [Select id, isconverted, convertedAccountId, convertedContactId from lead where id = :l.id];
        
        System.assertEquals(true,convertedLead.isConverted);
        System.assertEquals(ac.Id,convertedLead.convertedAccountId);
        System.assertEquals(affiliationRT,ac.recordtypeid);
        System.assertEquals(con.Id,convertedLead.convertedContactId);
        System.assertEquals(affiliationConRT,con.recordtypeid);
    }
}