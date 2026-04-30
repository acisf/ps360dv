public class AutoFBLeads {
    
    public  static List<FB_Lead__c> lstDownloadedLeads;
    public  static List<FB_Lead__c> lstLeads;
    public static List<Contact> lstContact;
    public static Map<string,Contact> mapContact;
    public static List<Case> lstCases;
    public static Map<String,Account> practicemap;
    //apex representation of JSON objects
    public Class Leads {
        List<data> data = new List<data>();
        Paging paging = new Paging();
        Error error;
    }
    
    public Class Data{
        String created_time = '';
        String id = '';
        String campaign_name = '';
        String form_id = '';
        String ad_id = '';
        String adset_name = '';
        String ad_name = '';
        String campaign_id = '';
        String platform = '';
        List<field_data> field_data = new List<field_data>();
    }
    
    public Class field_data{
        String name = '';
        List<String> values = new List<String>();
    } 
    
    public Class Error{
        String message = '';
    } 
    
    public Class Paging{
        Cursors cursors = new Cursors();
        String next = '' ;
        string previous = '';
    }
    
    public Class Cursors {
        string before = '';
        string after = '';
    }
    
    
    public static void downloadLeads(Facebook_Form__c form) {    
        
        String fb_token = [Select API_Token__c from Facebook_Setting__c limit 1].API_Token__c;	
        form.Debug_String__c = '';
        
        try{
            HttpResponse res = getLeadsFromAPI(form,fb_token);
            
            if(res!=null) {
                createLeadObjects(res,form);
                createContactObjects();                  
            }
            
            System.debug(form.FB_From_Date__c);
            system.debug(form.FB_After_Cursor__c);
            System.debug('Downloaded: ' + lstDownloadedLeads.size());
            System.debug('Created: ' + lstLeads.size());
            
            saveContacts();
            saveLeads();
            
            //lstCases = createCaseObjects();
            //saveCases();
        }
        catch(Exception e)  {
            System.debug(e);
            form.Debug_String__c += 'DOWNLOAD LEADS ERROR: ' + e.getMessage() + '\n';
        }
        finally  {
            update form;
        }
    } 
    
    public static HttpResponse getLeadsFromAPI(Facebook_Form__c fbForm, String token) {
        
        String fromDate, accesstoken, formid, filter, responsestring, url;
        DateTime dtFrom;
        Time t;
        
        fbForm.FB_From_Date__c = (fbForm.FB_From_Date__c == null) ? Date.today() - 1 : fbForm.FB_From_Date__c;      
        t = Time.newInstance(0,0,0,0);
        dtFrom = DateTime.newInstanceGMT(fbForm.FB_From_Date__c,t);
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();     
        HttpResponse res;
        
        accesstoken = token;
        formid = fbForm.Form_Id__c;        
        
        //build url from formid, access token, & timestamp 
        url = 'https://graph.facebook.com/' + formid + '/leads?access_token=' + accesstoken; 
        fromDate = String.valueOf(dtFrom.getTime() / 1000);
        filter = '[{\'field\':\'time_created\',\'operator\':\'GREATER_THAN\',\'value\':\'' + fromDate + '\'}]';
        url += '&filtering=' + filter;       
        url += '&fields=created_time,id,form_id,ad_id,adset_name,ad_name,campaign_id,campaign_name,field_data';
        
        if (!String.isEmpty(fbForm.FB_After_Cursor__c)) {
            url += '&after=' + fbForm.FB_After_Cursor__c;
        }
        
        //call the Facebook endpoint
        //system.debug(url);
        fbForm.Debug_String__c = 'FACEBOOK API CALL: ' + url + '\n';
        req.setTimeout(120000);
        req.setEndpoint(url);
        req.setmethod('GET');
        res=http.send(req);
        return res;
    }
    
    //create SF leads from the Facebook response
    public static void createLeadObjects(HttpResponse res, Facebook_Form__c fbForm) {
        
        practicemap = new Map<String,Account>();
        Map<String,Zip_Code__c> mapClosestPractice = new Map<String,Zip_Code__c>();
        List<Account> lstPractices = new List<Account>();
        List<Zip_Code__c> lstZips = new List<Zip_Code__c>();
        Set<String> fbleadids = new Set<String>();
        Set<String> locationIds = new Set<String>();
        Set<String> zipCodes = new Set<String>();
        
        Leads leads = (Leads)JSON.deserialize(res.getBody(), Leads.class);
        
        lstDownloadedLeads = new List<FB_Lead__c>();
        lstLeads = new List<FB_Lead__c>();
        
        fbForm.FB_After_Cursor__c = '';
        
        // handle API errors
        if(leads.error != null) {
            fbForm.Debug_String__c += 'FACEBOOK RETURNED ERROR: ' + leads.error.message + '\n';
            return;
        }
        
        // get next cursor
        if(leads.paging != null && leads.paging.next != null) {
            fbForm.FB_After_Cursor__c = leads.paging.cursors.after;
        }
        
        // first pass: create FB_Lead__c objects and collect ZIPs & location IDs
        for(Data d : leads.data) {
            
            FB_Lead__c fblead = new FB_Lead__c();
            DateTime dtCreated;
            
            fblead.FB_Form__c = fbForm.Id;
            fblead.FB_Lead_Id__c = d.id;
            fbleadids.add(d.id);
            
            // standard lead properties
            d.created_time = d.created_time.substring(0, d.created_time.indexOf('+')).replace('T',' ');
            dtCreated = DateTime.valueOf(d.created_time);
            
            fblead.FB_CreatedTime__c = dtCreated;
            fblead.FB_Date_Created__c = d.created_time;
            fblead.FB_Campaign_Name__c = d.campaign_name;
            fblead.FB_Form_Id__c = d.form_id;
            fblead.FB_Ad_Id__c = d.ad_id;
            fblead.FB_Ad_Name__c = String.isNotBlank(d.adset_name) 
                ? d.adset_name + '_' + d.ad_name 
                : d.ad_name;
            fblead.FB_Campaign_ID__c = d.campaign_id;
            fblead.FB_Platform__c = d.platform;
            
            // collect Facebook field data into a map
            Map<String, String> fields = new Map<String,String>();
            for(Field_data fd : d.field_data) {
                if(fd.values != null && !fd.values.isEmpty()) {
                    fields.put(fd.name, fd.values[0]);
                }
            }
            
            // set FB_Zip__c if present
            if(fields.containsKey('post_code')) {
                String zip = fields.get('post_code');
                if(String.isNotBlank(zip) && zip.length() <= 10) {
                    fblead.FB_Zip__c = zip;
                    zipCodes.add(zip);
                }
            }
            if(fields.containsKey('zip_code')) {
                String zip = fields.get('zip_code');
                if(String.isNotBlank(zip) && zip.length() <= 10) {
                    fblead.FB_Zip__c = zip;
                    zipCodes.add(zip);
                }
            }
            
            // set preferred location field
            if(fields.containsKey('which_location_do_you_prefer?')) {
                fblead.FB_Which_Location_Do_You_Prefer__c = fields.get('which_location_do_you_prefer?');
            }
            if(fields.containsKey('which_location_would_you_prefer?')) {
                fblead.FB_Which_Location_Do_You_Prefer__c = fields.get('which_location_would_you_prefer?');
            }
            
            // other FB fields
            fblead.FB_Email__c = fields.get('email');
            fblead.FB_First_Name__c = fields.get('first_name');
            fblead.FB_Last_Name__c = fields.get('last_name');
            fblead.FB_Comments__c = fields.get('comments');
            fblead.FB_Phone__c = (fields.containsKey('phone_number')) ? 
                fields.get('phone_number').replace('p:','').replace('+','') : null;
            
            if(fields.containsKey('full_name')) {
                String fullName = fields.get('full_name');
                fblead.FB_First_Name__c = getFirstName(fullName);
                fblead.FB_Last_Name__c = getLastName(fullName);
            }
            
            fblead.FB_What_Service__c = fields.containsKey('which_service_would_you_like_to_explore?') ?
                fields.get('which_service_would_you_like_to_explore?') :
            fields.get('which_dental_treatment_are_you_interested_in_learning_more_about?');
            
            fblead.FB_How_Quickly__c = fields.containsKey('how_soon_would_you_like_to_get_started_with_treatment?') ?
                fields.get('how_soon_would_you_like_to_get_started_with_treatment?') :
            fields.get('how_soon_are_you_needing_treatment?');
            
            fblead.FB_Using_Insurance__c = fields.containsKey('will_you_be_using_dental_insurance_for_your_visit?') ?
                fields.get('will_you_be_using_dental_insurance_for_your_visit?') :
            fields.get('do_you_plan_to_use_dental_insurance?');
            
            fblead.FB_Insurance_Provider__c = fields.containsKey('who_is_your_dental_insurance_provider?_(include_the_plan_name_if_you_know_it_so_we_can_check_coverage.)') ?
                fields.get('who_is_your_dental_insurance_provider?_(include_the_plan_name_if_you_know_it_so_we_can_check_coverage.)') :
            fields.get('please_provide_insurance_provider/plan_name.');
            
            // collect location IDs for practice lookup
            String adLocId = getLocationId(fblead.FB_Ad_Name__c);
            if(adLocId != '00000') {
                locationIds.add(adLocId);
            }
            
            lstDownloadedLeads.add(fblead);
        }
        
        // lookup practices
        if(!locationIds.isEmpty()) {
            lstPractices = [SELECT Id, FB_Notify_Practice__c, Location_ID_5_digit__c, FB_Call_Campaign_Opt_In__c
                            FROM Account WHERE Location_ID_5_digit__c IN :locationIds];
            for(Account a : lstPractices) {
                practicemap.put(a.Location_ID_5_digit__c, a);
            }
        }
        
        // lookup ZIPs
        if(!zipCodes.isEmpty()) {
            lstZips = [SELECT Id, Zip__c, 
                       Practice_1__c, Practice_1_Location_Id__c, Practice_1_brand__c,
                       Practice_2__c, Practice_2_Location_Id__c, Practice_2_brand__c,
                       Practice_3__c, Practice_3_Location_Id__c, Practice_3_brand__c
                       FROM Zip_Code__c WHERE Zip__c IN :zipCodes];
            for(Zip_Code__c z : lstZips) {
                mapClosestPractice.put(z.Zip__c, z);
            }
        }
        
        // assign practices using selection method
        for(FB_Lead__c lead : lstDownloadedLeads) {
            
            assignPractice(lead, practicemap, mapClosestPractice);
            
            // schedule dates
            DateTime dtFirstContact = DateTime.now().addDays(1);
            Date dateFirstContact = Date.newInstance(dtFirstContact.year(), dtFirstContact.month(), dtFirstContact.day()).addDays(1);            
            lead.FB_Scheduled_1__c  = (dtFirstContact.format('EEEE') == 'Sunday') ? dateFirstContact.addDays(1) : dateFirstContact;
            lead.FB_Scheduled_2__c  = ((dtFirstContact.addDays(3)).format('EEEE') == 'Sunday') ? dateFirstContact.addDays(4) : dateFirstContact.addDays(3);
            lead.FB_Scheduled_3__c  = ((dtFirstContact.addDays(7)).format('EEEE') == 'Sunday') ? dateFirstContact.addDays(8) : dateFirstContact.addDays(7);
        }
        
        // dedupe
        List<FB_Lead__c> lstExisting = [SELECT Id, FB_Lead_Id__c FROM FB_Lead__c WHERE FB_Lead_Id__c IN :fbleadids];
        Set<String> existingIds = new Set<String>();
        for(FB_Lead__c l : lstExisting) existingIds.add(l.FB_Lead_Id__c);
        
        lstLeads.clear();
        for(FB_Lead__c l : lstDownloadedLeads) {
            if(!existingIds.contains(l.FB_Lead_Id__c)) {
                lstLeads.add(l);
            }
        }
    }
    
    public static void assignPractice(FB_Lead__c lead, Map<String, Account> practiceMap, Map<String, Zip_Code__c> zipMap) {
        
        String adLocationId = getLocationId(lead.FB_Ad_Name__c);
        System.debug('Ad name: ' + lead.FB_Ad_Name__c);
        String preferredLocationId = '00000';
        
        System.debug('ad Location ' + adLocationId);
        
        
        // check preferred location fields
        if(lead.FB_Which_Location_Do_You_Prefer__c != null) {
            preferredLocationId = getLocationId(lead.FB_Which_Location_Do_You_Prefer__c);
        }
        
        // Priority: Ad Name
        if(adLocationId != '00000' && practiceMap.containsKey(adLocationId)) {
            lead.FB_Practice_Id__c = adLocationId;
            lead.FB_Practice__c = practiceMap.get(adLocationId).Id;
            System.debug('Using ad name for location');
            return;
        }
        
        // Preferred location
        if(preferredLocationId != '00000' && practiceMap.containsKey(preferredLocationId)) {
            lead.FB_Practice_Id__c = preferredLocationId;
            lead.FB_Practice__c = practiceMap.get(preferredLocationId).Id;            
            System.debug('Using preferred location for location');
            return;
        }
        
        // ZIP-based lookup
        if(String.isNotBlank(lead.FB_Zip__c) && zipMap.containsKey(lead.FB_Zip__c)) {
            Zip_Code__c z = zipMap.get(lead.FB_Zip__c);
            if(z.Practice_1_brand__c.startsWith('Affordable Dentures')) {
                lead.FB_Practice__c = z.Practice_1__c;
                lead.FB_Practice_Id__c = z.Practice_1_Location_Id__c;
            } else if(z.Practice_2_brand__c.startsWith('Affordable Dentures')) {
                lead.FB_Practice__c = z.Practice_2__c;
                lead.FB_Practice_Id__c = z.Practice_2_Location_Id__c;
            } else if(z.Practice_3_brand__c.startsWith('Affordable Dentures')) {
                lead.FB_Practice__c = z.Practice_3__c;
                lead.FB_Practice_Id__c = z.Practice_3_Location_Id__c;
            }
            
            System.debug('Using zip location');
            return;
        }
        
        // Default fallback
        lead.FB_Practice_Id__c = '00000';
        lead.FB_Practice__c = null;
    }
    
    public static String getFirstName(String fullname) {
        String first_name = '';
        String last_name = '';
        String[] result = fullname.split(' ');
        for(String s: result) {
            if (first_name == '') {
                first_name = s;
            }
            last_name = s;
        }
        return first_name;
    }
    
    public static String getLastName(string fullname) {
        String first_name = '';
        String last_name = '';
        String[] result = fullname.split(' ');
        for(String s: result) {
            if (first_name == '') {
                first_name = s;
            }
            last_name = s;
        }
        return last_name;
    }
    
    //create contacts 
    public static void createContactObjects() {
        
        lstContact = new List<Contact>(); 
        Set<String> contactemails = new Set<String>();
        mapContact = new Map<string,Contact>();
        
        for(FB_Lead__c fb:lstLeads) {     
            contactemails.add(fb.FB_Email__c);
        } 
        
        for(Contact cont:[select email,id,mobilePhone, otherPhone, FB_Lead_Id__c,FB_Submit_Date__c from contact where email in: contactemails]) {
            mapContact.put(cont.email, cont);
        }
        
        for(FB_Lead__c fb:lstLeads) {  
            
            if(mapContact.get(fb.FB_Email__c) !=null) {
                fb.FB_Contact__c = mapContact.get(fb.FB_Email__c).Id;
                mapContact.get(fb.FB_Email__c).FB_Lead_Id__c = fb.FB_Lead_Id__c;
                if(mapContact.get(fb.FB_Email__c).FB_Submit_Date__c == null) {
                    mapContact.get(fb.FB_Email__c).FB_Submit_Date__c = DateTime.valueOf(fb.FB_Date_Created__c);
                }
                if(mapContact.get(fb.FB_Email__c).MobilePhone == null) {
                    mapContact.get(fb.FB_Email__c).MobilePhone = mapContact.get(fb.FB_Email__c).OtherPhone;
                }
            } else { 
                Contact cont = new Contact();
                cont.AccountId = fb.FB_Practice__c;
                cont.Email = fb.FB_Email__c;
                cont.MobilePhone = fb.FB_Phone__c;
                cont.LastName = fb.FB_Last_Name__c;
                cont.FirstName = fb.FB_First_Name__c;
                cont.FB_Lead_Id__c = fb.FB_Lead_Id__c;
                cont.FB_Submit_Date__c = DateTime.valueOf(fb.FB_Date_Created__c);
                if(cont.AccountId != null) {
                    lstContact.add(cont);
                }
            }
        }             
    }
    
        /*
    //create cases
    public static List<Case> createCaseObjects() {
        Id fbid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Facebook Lead').getRecordTypeId(); 
        Set<Id> contacts = new Set<Id>();
        Set<String> emails = new Set<String>();
        List<Case> lstExistingCase = new List<Case>();
        Set<Id> existingcontacts = new Set<Id>();
        
        lstCases = new List<Case>(); 
        
        //dedupe
        for(FB_Lead__c fb: lstLeads) {
        contacts.add(fb.FB_Contact__c);
        emails.add(fb.FB_Email__c);
        }
        
        lstExistingCase = [SELECT Id, ContactId FROM Case
        WHERE RecordTypeId =: fbid
        AND ContactId in: contacts];
        
        for(Case c: lstExistingCase) {
        existingcontacts.add(c.ContactId);
        }
        
        lstExistingCase = [SELECT Id, ContactId FROM Case
        WHERE RecordTypeId =: fbid
        AND SuppliedEmail in: emails];
        
        for(Case c: lstExistingCase) {
        if(!existingcontacts.contains(c.ContactId)) 
        existingcontacts.add(c.ContactId);
        }
        
        
        for(FB_Lead__c fb : lstLeads) {
        
        Account a = practicemap.get(fb.FB_Practice_Id__c);
        
        if(a!=null && a.FB_Call_Campaign_Opt_In__c && !existingcontacts.contains(fb.FB_Contact__c)) {
        
        Case c = new Case(); 
        c.OwnerId = '00G1R000003FjcC';
        c.RecordTypeId = fbid;
        c.AccountId = fb.FB_Practice__c;
        c.ContactId = fb.FB_Contact__c;                
        c.Facebook_Lead_Id__c = fb.FB_Lead_Id__c;
        c.SuppliedPhone = fb.FB_Phone__c;
        c.SuppliedEmail = fb.FB_Email__c;
        c.Origin = 'Facebook';
        c.Status='New';
        
        if(fb.FB_Practice_Id__c == '92001' && fb.FB_Form_Id__c == '478177831022514') { 
        c.Subject = 'Facebook Lead [CareCredit]';
        }
        else {
        c.Subject='Facebook Lead - ' + 'Location ' + fb.FB_Practice_Id__c;
        }
        
        if(fb.FB_Contact__c == null) {
        c.Description += 'First Name: ' + fb.FB_First_Name__c + '\n';
        c.Description += 'Last Name: ' + fb.FB_Last_Name__c+ '\n';
        c.Description += 'Phone: ' + fb.FB_Phone__c+ '\n';
        c.Description += 'Email: ' + fb.FB_Email__c+ '\n';
        } else {
        c.Description = fb.FB_Comments__c;
        }
        
        lstCases.add(c); 
        }
        }   
        
        return lstCases;
        } 
        
        public static void saveCases() {
        Database.insert(lstCases,false);
    }
    */
    
    public static void saveContacts() {
        
        update mapContact.values();
        insert lstContact;
        
        for(Contact cont: lstContact) {
            mapContact.put(cont.email, cont);
        } 
    }
    
    public static void saveLeads() {
        for(FB_Lead__c fbLead:lstLeads) {
            if(mapContact.get(fbLead.FB_Email__c) !=null) {
                fbLead.FB_Contact__c = mapContact.get(fbLead.FB_Email__c).Id;
            }       
        }
        
        insert lstLeads;
    }
    
    public static String getLocationId(String strIn) {
        if (String.isBlank(strIn)) {
            return '00000';
        }
        
        // Match any 4 or 5 digit number in the string
        Pattern p = Pattern.compile('\\d{4,5}');
        Matcher m = p.matcher(strIn);
        
        while (m.find()) {
            String candidate = m.group();
            
            // Pad 4-digit IDs
            if (candidate.length() == 4) {
                candidate = '0' + candidate;
            }
            
            // Ignore 92024
            if (candidate == '92024') {
                continue;
            }
            
            return candidate; // First valid match
        }
        
        return '00000';
    }
}