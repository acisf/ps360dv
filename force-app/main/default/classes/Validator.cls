public class Validator {
    
    public static Set<string> domains = new set<string>();
    public static Set<string> commonerrors = new set<string>();
        
    public class Entries {
        public List<Entry> entries = new List<Entry>();
    }
    
    public class Entry {
        public String inputData = '';
    }
    
    public class Overview {
        public string id = '';
        public string status = '';
    }
    
    public class SubmissionResponse {
        public Overview overview;
    }
    
    public class Meta {
        public string cursor = '';
        public string isTruncated = 'false';
    }
    
    public class Data {
        public string index = '0';
        public string inputData = '';
        public string completedOn = '';
        public string emailAddress = '';
        public string status = '';
        public string classification = '';  
    }
    
    public class ValidationResponse {
        Meta meta;
        Data[] data;
    }
    
    public static void setTopLevelDomains() {
        list<domain__c> lstDomains = [select DomainName__c,TopLevel__c,Valid__c from Domain__c];
        for(domain__c d: lstDomains) {
            if(d.TopLevel__c && d.Valid__c)
                domains.add(d.DomainName__c.toLowerCase());
            else
                commonerrors.add(d.DomainName__c.toLowerCase());
        }
    }   
    
    public static string getTopLevelDomain(string email) {
        string toplevel ='';
        if(String.isNotBlank(email)) {
            if(email.lastIndexOf('.') > 0) {
                toplevel= email.toLowerCase().substring(email.lastIndexOf('.')+1);
            }            
        } 
        return toplevel;       
    }
    
    public static string getDomain(string email) {
        string toplevel ='';
        if(String.isNotBlank(email)) {
            if(email.lastIndexOf('@') > 0) {
                toplevel= email.toLowerCase().substring(email.lastIndexOf('@')+1);
            }            
        } 
        return toplevel;       
    }
    
    public static Boolean hasValidDomain(String email) {
        String domain = getDomain(email);
        return !commonerrors.contains(domain);
    }
    
    public static Boolean hasValidTopLevelDomain(String email) {        
        String topLevel= getTopLevelDomain(email);
        return domains.contains(topLevel);
    }
    
    public static Boolean isValidEmail(String email) {
        Boolean valid = false;
        
        if(String.isNotBlank(email)) {
            String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: http://www.regular-expressions.info/email.html
            Pattern MyPattern = Pattern.compile(emailRegex);
            Matcher MyMatcher = MyPattern.matcher(email);
            
            if (MyMatcher.matches()) 
                valid = true;
        }
        
        return valid; 
    }
    //
    public static string submitValidationJob(list<string> lstEmail) {        
        
        Entries ent = new Entries();
        string strJobId = '';
        
        for ( string email: lstEmail) {
            Entry e = new Entry();
            e.inputData = email;     
            ent.entries.add(e);
        }
        
        String data = JSON.serialize(ent);
        String username = 'appteam@affordablecare.com';
        String pwd = 'AppT3amVer1fier!';
        HTTP h = new HTTP();        
        HTTPRequest r = new HTTPRequest();        
        r.setEndpoint('https://api.verifalia.com/v2.4/email-validations');        
        Blob headerValue = Blob.valueOf(username + ':' + pwd);        
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);        
        r.setHeader('Authorization', authorizationHeader);
        r.setHeader('Content-Type','application/json') ;       
        r.setMethod('POST');
        System.debug(data);
        r.setBody(data); 
        r.setTimeout(20000);
        HTTPResponse resp = h.send(r);
        
        System.debug('Status Code ' + resp.getStatusCode());
        
        if(resp.getStatusCode() == 200 || resp.getStatusCode() == 202) {
            SubmissionResponse sr = (SubmissionResponse)JSON.deserialize(resp.getbody(),SubmissionResponse.class); 
            
            if(sr.overview != null) {
                strJobId = sr.overview.id;
            }
            
        } 
        
        return strJobId;
    }
    
    //ex: 5e6cba51-3e8b-465d-b107-83dfb8285df0      
    public static List<string> getValidationJobFailures(string jobid) {         
        List<string> lstFailedEmails = null;
        String username = 'appteam@affordablecare.com';
        String pwd = 'AppT3amVer1fier!';        
        HTTP h = new HTTP();        
        HTTPRequest r = new HTTPRequest();        
        r.setEndpoint('https://api.verifalia.com/v2.4/email-validations/' + jobid + '/entries');        
        Blob headerValue = Blob.valueOf(username + ':' + pwd);        
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);        
        r.setHeader('Authorization', authorizationHeader);     
        r.setMethod('GET');         
        HTTPResponse resp = h.send(r);
        
        if(resp.getStatusCode() == 200) {
            ValidationResponse vr = new ValidationResponse();
            vr = (ValidationResponse) JSON.deserialize(resp.getbody(), ValidationResponse.class);     
            
            if(vr.data !=null) {
                lstFailedEmails = new List<string>();
                for(Data d: vr.data) {
                    system.debug(d.emailAddress + ' ' + d.classification + ' ' + d.inputData);
                    if(d.classification == 'Undeliverable' || d.classification == 'Risky')
                        lstFailedEmails.add(d.inputData);    //lstFailedEmails.add(d.emailAddress); MN- Orignal
                }   
            }
        }       
        
        system.debug(lstFailedEmails);
        return lstFailedEmails;
    }   
    
    // Method to fetch the authentication token from Verifalia
    public static String getAuthToken() {
        HTTP http = new HTTP();
        HTTPRequest request = new HTTPRequest();
        request.setEndpoint('https://api.verifalia.com/v2.4/auth/tokens');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        
        String username = 'affordablecarellc';
        String password = 'Ilove2SF!!!';
        String cred = '{username:"'+username + '",password:"' + password + '"}';
       
        request.setBody(cred);
        
        HTTPResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String accessToken = (String)resBody.get('access_token');
            return accessToken;
        } else {
            System.debug('Error getting auth token: ' + response.getStatus());
            return null;
        }
    }
    
    
}