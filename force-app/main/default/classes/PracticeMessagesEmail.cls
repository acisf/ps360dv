//This class sends a monthly email of two excel attachments
//containing acive practice messages and scheduling requirements

public class PracticeMessagesEmail {
    
    public static HttpResponse getActivePracticesReport() {
        Http http = new Http();
        HttpRequest request;
        HttpResponse  response;
        
        string reportId = '00O36000007ZBAy';
		        
        //active practice messages
        request = new HttpRequest();
        request.setTimeout(120000);
        request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v46.0/analytics/reports/' + reportId);
        request.setMethod('GET');  
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        request.setHeader('Accept', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'); 
        response= http.send(request);
        return response;
    }
    
    public static HttpResponse getSchedulingRequirements() {
        HttpRequest request;  
        HttpResponse response;
        Http http = new Http();
       
        
        //scheduling requirements
        request = new HttpRequest();
        request.setTimeout(120000);
        
         String reportId = '00O1R000007ZQ6e';
        request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() +
                            '/services/data/v46.0/analytics/reports/' + reportId);
        request.setMethod('GET');  
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        request.setHeader('Accept', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        response = http.send(request);
        return response;
    }
    
     public static HttpResponse getPracticeAttributes() {
        Http http = new Http();
        HttpRequest request;
        HttpResponse  response;
        
        string reportId = '00OUR00000GJaZd';
		        
        //practice attributes
        request = new HttpRequest();
        request.setTimeout(120000);
        request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v46.0/analytics/reports/' + reportId);
        request.setMethod('GET');  
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        request.setHeader('Accept', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'); 
        response= http.send(request);
        return response;
    }
    
    
    @Future(callout=true)
    public static void sendEmail() {   
        
        Blob blobPM;
        Blob blobSR;
        Blob blobPA;
        Messaging.EmailFileAttachment efaPM;
        Messaging.EmailFileAttachment efaSR;
         Messaging.EmailFileAttachment efaPA;
        List<Messaging.SingleEmailMessage> allmsg;
        Messaging.SingleEmailMessage mail;
        List<String> toAddr; 
        List<String> ccAddr; 
        List<String> bccAddr; 
        //create blob / email attachment from httpresponse 
        blobPM = getActivePracticesReport().getBodyAsBlob();         
        efaPM = new Messaging.EmailFileAttachment();
        efaPM.setFileName('Active_Practice_Messages.xlsx');
        efaPM.setContentType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        efaPM.setBody(blobPM);  
        
        blobSR = getSchedulingRequirements().getBodyAsBlob();         
        efaSR = new Messaging.EmailFileAttachment();
        efaSR.setFileName('Scheduling_Requirements.xlsx');
        efasr.setContentType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        efaSR.setBody(blobSR);  
        
        blobPA = getPracticeAttributes().getBodyAsBlob();         
        efaPA = new Messaging.EmailFileAttachment();
        efaPA.setFileName('Practice_Attributes.xlsx');
        efaPA.setContentType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        efaPA.setBody(blobPA);  
        
        //instantiate email object
        mail = new Messaging.SingleEmailMessage();
        allmsg = new List<Messaging.SingleEmailMessage>();  
        mail.setSubject('Scheduling Requirements, Active Messages, and Pratice Attributes');
        toAddr = new List<String>(); 
        ccAddr = new List<String>();
        bccAddr = new List<String>(); 
        
    
        toAddr.add('Div1dir@affordablecare.com');  
        toAddr.add('div2dir@affordablecare.com'); 
        toAddr.add('div3dir@affordablecare.com');  
        toAddr.add('div4dir@affordablecare.com'); 
        ccAddr.addAll(new List<String>{'Angela.Privette@affordablecare.com',
                         'margaret.hernandez@affordablecare.com',
                         'Jana.McKee@affordablecare.com',
                         'laura.lamos@affordablecare.com',
                         'shinto.chakuncal@affordablecare.com'
                });

        bccAddr.add('AppTeam@affordablecare.com'); 
        
        mail.setUseSignature(false);
        mail.setBCCSender(false);
        mail.toaddresses = toAddr;
        mail.ccaddresses = ccAddr;
        mail.bccaddresses = bccAddr;
        mail.htmlbody = 'Attached please find the following reports from Patient Services for your review:<br/><br/>' +
                        '<b>Active Practice Messages</b> - A note/message from the practice that is displayed on the practice record in the call center<br/>' +
            			'<b>Scheduling Requirements</b> - A scheduling requirement of a practice that is displayed on the practice record in the call center.<br/>' +
            			'<b>Practice Attributes</b>- Office hours, insurance accepted, and services provided by a practice, as displayed on the practice record in the call center.';
        
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{efaPM,efaSR,efaPA});
        mail.setSaveAsActivity(true); 
        
        allmsg.add(mail);
        
        //send emails
        Messaging.sendEmail(allmsg,false);
    }
}