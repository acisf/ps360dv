public class LeadConversion {

    @InvocableMethod (label='LeadConversion')
    public static void autoConvertLead(List<Id> leadIds) {
        Id affiliationRT, affiliationConRT;        
        List<Lead> lstLeads = new List<Lead>();
        Map<String,Id> mapLeadCompany = new Map<String,Id>();
        Map<Id,Id> mapLeadPractice = new Map<Id,Id>();
        Map<Id,String> mapLeadOwner = new Map<Id,String>();
        LeadStatus leadStatus = new LeadStatus();
        Database.LeadConvert leadConvert;
        List<Database.LeadConvert> lstLeadConvert = new List<Database.LeadConvert>();
        List<Database.LeadConvertResult> lstLeadConvertResult = new List<Database.LeadConvertResult>(); 
        Set<Id> accIds = new Set<Id>();  
        Set<Id> conIds = new Set<Id>();         
                
        affiliationRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliations').getRecordTypeId();
        affiliationConRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Affiliations').getRecordTypeId();
        mapLeadOwner = getLeadOwnerThatIsNotQueue(leadIds);
        mapLeadCompany = getCompanyFromLead(leadIds);
        mapLeadPractice = findExistingPracticeFromCompany(affiliationRT,mapLeadCompany);
        leadStatus = getConvertedLeadStatus();    

        for(Id leadId: leadIds){
            leadConvert = new Database.LeadConvert();
            leadConvert = setLeadConversionStatus(leadConvert,leadId,leadStatus,mapLeadPractice,mapLeadOwner);
            lstLeadConvert.add(leadConvert);
        }  

        lstLeadConvertResult = convertLead(lstLeadConvert);

        for(Database.LeadConvertResult leadResult: lstLeadConvertResult){
            accIds.add(leadResult.getAccountID());
            conIds.add(leadResult.getContactId());
        }

        updatePracticeToAffiliationRT(accIds,affiliationRT);
        updateContactToAffiliationRT(conIds,affiliationConRT);
    }

    public static Map<Id,String> getLeadOwnerThatIsNotQueue(List<Id> leadIds){
        List<Lead> lstLeads = [Select id, ownerId from lead where id in :leadIds];
        Map<Id,String> mapLeadOwner = new Map<Id,String>();
        for(Lead l: lstLeads){
            if(String.ValueOf(l.ownerId).startsWith('00G'))
                mapLeadOwner.put(l.id,UserInfo.getUserId());
            else
                mapLeadOwner.put(l.Id,l.OwnerId);
        }
        return mapLeadOwner;
    }

    public static LeadStatus getConvertedLeadStatus(){
        return ([Select Id,ApiName from LeadStatus where isConverted = true and ApiName = 'NDA' Limit 1]);
    }

    public static Database.LeadConvert setLeadConversionStatus(Database.LeadConvert leadConvert,Id leadId,LeadStatus leadStatus,
                                                                Map<Id,Id> mapLeadPractice,
                                                                Map<Id,String> mapLeadOwner){
        leadConvert.setLeadId(leadId);
        if(Test.isRunningTest())
            leadConvert.setConvertedStatus('NDA');
        else
            leadConvert.setConvertedStatus(leadStatus.ApiName);
        leadConvert.setDoNotCreateOpportunity(true);
        leadConvert.setOwnerId(mapLeadOwner.get(leadId));
        if(mapLeadPractice.size() > 0){
            leadConvert.setAccountId(mapLeadPractice.get(leadId));
        }
        return leadConvert;
    }

    public static List<Database.LeadConvertResult> convertLead(List<Database.LeadConvert> lstLeadConvert){
        List<Database.LeadConvertResult> lstLeadConvertResult = new List<Database.LeadConvertResult>();
        if(lstLeadConvert.size() > 0){
            lstLeadConvertResult = Database.convertLead(lstLeadConvert);
        }
        return lstLeadConvertResult;
    }

    public static Map<String,Id> getCompanyFromLead(List<Id> leadIds){
        Map<String,Id> mapLeadCompany = new Map<String,Id>();
        
        For(Lead l: [Select Id, company from Lead where id in :leadIds]){
            mapLeadCompany.put(l.company,l.id);
        }
        return mapLeadCompany;
    }

    public static Map<Id,Id> findExistingPracticeFromCompany(Id affiliationRT,Map<String,Id> mapLeadCompany){
        Map<Id,Id> mapLeadPractice = new Map<Id,Id>();
        if(mapLeadCompany.size() > 0){
            Id leadId;        
            for(Account ac: [Select Id, name from Account where 
                             //recordtypeid = :affiliationRT and
                             name in :mapLeadCompany.keyset()]){
                                leadId = mapLeadCompany.get(ac.name);
                                mapLeadPractice.put(leadId,ac.Id);
                            }
        }
        return mapLeadPractice;
    }

    public static void updatePracticeToAffiliationRT(Set<Id> accIds,Id affiliationRT){
        List<Account> lstPractices = new List<Account>();
        list<Account> lstUpdPractices = new List<Account>();
        lstPractices = [Select Id, recordtypeid from Account where id In :accIds
                        and recordtypeid != :affiliationRT];

        for(Account a: lstPractices){
            a.recordtypeid = affiliationRT;
            lstUpdPractices.add(a);
        }

        if(lstUpdPractices.size() > 0)
            Database.update(lstUpdPractices,false);
    }

    public static void updateContactToAffiliationRT(Set<Id> conIds,Id affiliationConRT){
        List<Contact> lstContact = new List<Contact>();
        list<Contact> lstUpdContact = new List<Contact>();
        lstContact = [Select Id, recordtypeid from Contact where id In :conIds
                        and recordtypeid != :affiliationConRT];

        for(Contact con: lstContact){
            con.recordtypeid = affiliationConRT;
            lstUpdContact.add(con);
        }

        if(lstUpdContact.size() > 0)
            Database.update(lstUpdContact,false);
    }
}