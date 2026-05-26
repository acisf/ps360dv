public class ZetaEventTriggerHandler {
    //json 
    class JZetaEvent {
        string user_id;
        string event_type;
        string timestamp;
        string practiceid;
        string apptid;
        string apptdate;
        string appttime;
        string apptdatetime;        
    } 
    
    public void beforeInsert(List<zeta_event__c> lstEvent) {
        JZetaEvent jEvent; 
        
        for(zeta_event__c ev: lstEvent) {
            try {
            jEvent = (JZetaEvent) JSON.deserialize(ev.JSON__c,JZetaEvent.class);
            ev.user_id__c = jEvent.user_id;
            ev.event_type__c = jEvent.event_type;
            ev.timestamp__c = jEvent.timestamp;
            ev.practiceid__c = jEvent.practiceid;
            ev.apptid__c = jEvent.apptid;
            ev.apptdate__c = Jevent.apptdate;
            ev.appttime__c = JEvent.appttime;
            ev.apptdatetime__c = JEvent.apptdatetime;  
            if(ev.practiceid__c != null)
                ev.practiceid__c =ev.practiceid__c.leftpad(5,'0');
            }
            catch(Exception e) {
                
            }
        }  
    }
    
}