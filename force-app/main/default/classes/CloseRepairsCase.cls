public class CloseRepairsCase {
    //public static List<Case> repairs_cases = [Select Id, Status, Createddate from Case where team__c = 'Repairs' and isClosed = false];        
    public static List<Case> repairs_cases = [Select Id, Status, Createddate from Case where team__c = 'Dental Equipment Repairs' and isClosed = false];
    public static Map<Id,DateTime> case_det = new Map<Id,DateTime>();
    public static Date dt = Date.today();
    public static List<FeedItem> feed = new List<FeedItem>();
    public static List<Case> case_upd_reply = new List<Case>();
    public static List<EmailMessage> email_replies = new List<EmailMessage>();
    public static String txt_body, wo_no;    
    public static Set<Id> caseIds = new Set<Id>();
    
    public static void autoCloseRepairsCase(){
        
        populateMapcase_detWithCaseDetails();
        getEmailRepliesFromHenrySchein();
        scanEmailReplies();
        updateCase();
        
    }
    
    public static void populateMapcase_detWithCaseDetails(){
        for(Case c: repairs_cases){            
            case_det.put(c.id,c.CreatedDate);
        }
    }
    
    public static void getEmailRepliesFromHenrySchein(){
        email_replies = [Select id, parentId, TextBody from EmailMessage 
                         where parentId in :case_det.keySet() and incoming = true and FromAddress Like '%@henryschein.com' ];            
    }
    
    public static void scanEmailReplies(){
        if(email_replies.size() > 0){         
            for(EmailMessage em : email_replies){
                extractWorkOrderNoInEmail(em);      
            } //end - for(EmailMessage em : email_replies)
        } //end - if(email_replies.size() > 0)
    }
    
    public static void extractWorkOrderNoInEmail(EmailMessage em){
        txt_body = em.TextBody;
       // String expr = 'SR[0-9]+';
        String expr = '(SR.*[0-9]+)|(SR#.*[0-9]+)';
        Pattern p = Pattern.compile(expr);
        Matcher match = p.matcher(txt_body);
        /*if WO is found*/
        if(match.find()){	
        	wo_no = match.group(0);
			System.debug('WO no ' + wo_no);         
            createFeedWithWorkOrder(em);
            closeCase(em);             		
         } 
        /*If WO is not found in the email reply and case is open for a week*/
         else
         	checkCaseIsOpenForaWeek(em); 	  
    }
    
    public static void createFeedWithWorkOrder(EmailMessage em){
        FeedItem f = new FeedItem();   
        f.ParentId = em.ParentId;
        f.Body = 'The case details are forwarded to Henry Schein. Work Order # ' + wo_no;
        f.Type = 'TextPost';
        f.Visibility = 'AllUsers';
        feed.add(f);
    }
    
    public static void checkCaseIsOpenForaWeek(EmailMessage em){
        Date cr_dt = Date.valueOf(case_det.get(em.ParentId));
        Integer days = cr_dt.daysbetween(dt);
        System.debug('Createddate ' + cr_dt + ' Days between ' + days);
        if(days > 7)
            closeCase(em);
    }
    
    public static void closeCase(EmailMessage em){
        Case case_upd = new Case();        
        if(!caseIds.contains(em.ParentId)){
            caseIds.add(em.ParentId);
            case_upd.id = em.ParentId;
            case_upd.Status = 'Resolved';
            System.debug('Case Status: ' + case_upd.Status);
            case_upd_reply.add(case_upd);  
        }
    }
    
    public static void updateCase(){
        try{
            insert feed;
			update case_upd_reply;            
        }
        catch(Exception e){
            System.debug('Error when closing Repairs case: ' + e.getMessage());
        }        
    }

}