public with sharing class ContactSearchController {
    public List<Contact> conList {get; set;}
    public String searchString {get; set;}

    public ContactSearchController() {
        this.conList = new List<Contact>();
    }

    // Constructor for Visualforce standard controller support
    public ContactSearchController(ApexPages.StandardController controller) {
        this();
    }

    @AuraEnabled(cacheable=false)
    public static List<Contact> getContacts(String searchString) {
        if (String.isNotBlank(searchString) && searchString.length() > 1) {
            String searchQuery = 'FIND \'' + searchString + '*\' IN ALL FIELDS RETURNING Contact(Id, Name, Email, NVM_HomePhone__c,NVM_MobilePhone__c,Phone, OtherPhone, MobilePhone,HomePhone, Account.Name LIMIT 6)';
            List<List<SObject>> searchList = Search.query(searchQuery);
            if (!searchList.isEmpty() && !searchList[0].isEmpty()) {
                return (List<Contact>)searchList[0];
            }
        }
        return new List<Contact>();
    }

    public void search() {
        if (String.isNotBlank(searchString) && searchString.length() > 1) {
            this.conList = getContacts(this.searchString);
            if (conList.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Sorry, no results were found'));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter at least two characters'));
        }
    }
}