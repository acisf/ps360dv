@isTest
public class SpamDeleteTest {
    
    @istest
    static void testSpam_Del() {
        List<Case> lstC = new List<Case>();
        Case c = new Case();
        c.Name_of_Organization__c = 'google';
        c.Origin = 'Web';
        c.Status = 'Rejected';
        lstC.add(c);
        insert lstC;
        SpamDelete.deleteSpamCase(new list<Id> {c.id});
    }

}