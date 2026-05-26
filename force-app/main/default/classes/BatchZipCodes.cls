global class BatchZipCodes implements Database.Batchable<sobject> {
    
    global Database.QueryLocator start (Database.BatchableContext bc) {
        String sql = 'select id, latitude__c,longitude__c from zip_code__c';
        return Database.getQueryLocator(sql);
    }	
    
    global void execute(Database.BatchableContext bc, list<sobject> scope) {
        List<zip_code__c> lstUpdate = new List<zip_code__c>();
        
        for(sObject objScope: scope) {
            Zip_Code__c zip = (Zip_code__c) objScope;
            ZipCodeController controller = new ZipCodeController();
            lstUpdate.add(controller.calcNearestAccounts(zip));
        }
        
        Database.update(lstUpdate,false);
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('ZipBatch completed successfully');
    }

}