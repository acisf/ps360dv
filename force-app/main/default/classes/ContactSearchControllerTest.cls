@isTest
public class ContactSearchControllerTest {
    
    // Existing tests remain unchanged
    @isTest
    static void testSampleSearch(){
        Contact cont = new Contact();
        cont.FirstName = 'Test'; // Ensure required fields are set
        cont.LastName = 'Sean Alloway';
        cont.AccountId = '0013600000VHgxq';
        insert cont;
        
        PageReference pageRef = new PageReference('/apex/NVM_Contact_Search');
        Test.setCurrentPage(pageRef);
        
        ContactSearchController contSearch = new ContactSearchController();
        contSearch.searchString = 'Alloway';
        contSearch.search();       
    }
    
    @isTest
    static void testSampleSearch1(){
        Contact cont = new Contact();
        cont.FirstName = 'Test'; // Ensure required fields are set
        cont.LastName = 'Sean Alloway';
        cont.AccountId = '0013600000VHgxq';
        insert cont;
        
        PageReference pageRef = new PageReference('/apex/NVM_Contact_Search');
        Test.setCurrentPage(pageRef);
        
        ContactSearchController contSearch = new ContactSearchController();
        contSearch.searchString = '1';
        contSearch.search(); 

        System.assert(ApexPages.hasMessages());
    }
    
    // Test the @AuraEnabled method for LWC
    @isTest
    static void testAuraEnabledGetContacts() {
        Contact cont = new Contact();
        cont.FirstName = 'Test'; // Ensure required fields are set
        cont.LastName = 'Sean Alloway';
        cont.AccountId = '0013600000VHgxq';
        insert cont;
        
        Test.startTest();
        // Directly invoke the @AuraEnabled method
        List<Contact> results = ContactSearchController.getContacts('Alloway');
        Test.stopTest();
        
        // Assert that the method was called without concern for the results
        // This simply ensures the method can be called successfully
        System.assertNotEquals(null, results, 'The @AuraEnabled method should execute without throwing an error.');
    }
}