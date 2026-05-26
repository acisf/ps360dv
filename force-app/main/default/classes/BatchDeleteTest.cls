@isTest
public class BatchDeleteTest {
    
    @isTest
    public static void runtest() {
        Account a = new Account(Name='Test');
        insert a;
        BatchDelete BDel = new BatchDelete();
        Datetime d = Datetime.now();
        d = d.addDays(-1);
        // Query for selecting the documents to delete
        BDel.query = 'SELECT Id FROM Account WHERE CreatedDate > '+ d.format('yyyy-MM-dd')+'T'+  d.format('HH:mm')+':00.000Z';
        
        ID batchprocessid = Database.executeBatch(BDel);
        System.debug('Returned batch process ID: ' + batchProcessId);
    }
}