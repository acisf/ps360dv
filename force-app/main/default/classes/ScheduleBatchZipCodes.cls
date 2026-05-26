global class ScheduleBatchZipCodes implements Schedulable { 
//System.schedule('Zip Batch','0 00 03 * * ? *',new ScheduleBatchZipCodes()    
 global void execute(SchedulableContext SC) { 
        
        List<Account> lstAccount;
     	List<Zip_Code__c> lstZip;
     
     	//re-run the zip batch if there are any new zip codes, practices, or modified practices
     	lstAccount = [select id from account where
                     CreatedDate >:DateTime.now().addDays(-1) OR
                     LastModifiedDate >: DateTime.now().addDays(-1)];
     
     	lstZip = [select id from Zip_Code__c where
                     CreatedDate >:DateTime.now().addDays(-1)];
     
     	if(lstAccount.size() > 0 || lstZip.size() > 0) {
     		Database.executeBatch(new BatchZipCodes());
     	}
        
    }
}