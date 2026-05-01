public class TreatmentFinderLeadNotifier {

    public static void sendNotifications() {

        // 0. Org-Wide Email
        OrgWideEmailAddress[] owea = [
            SELECT Id FROM OrgWideEmailAddress 
            WHERE Address = 'patientsupport@affordablecare.com'
            LIMIT 1
        ];

        // 1. Get Leads
        List<Lead> leads = [
            SELECT Id, FirstName, LastName, Email, Phone, Location_Id__c, TF_JSON__c
            FROM Lead
            WHERE RecordType.Name = 'Treatment Finder'
            AND Lead_Notification_Sent_Date__c = NULL
            AND CreatedDate = LAST_N_DAYS:1
        ];

        if (leads.isEmpty()) return;

        // 2. Collect Location IDs
        Set<String> locationIds = new Set<String>();
        for (Lead l : leads) {
            if (String.isNotBlank(l.Location_Id__c)) {
                locationIds.add(l.Location_Id__c);
            }
        }

        if (locationIds.isEmpty()) return;

        // 3. Map Location → Account
        Map<String, Account> locationToAccount = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, Name, Location_Id__c
            FROM Account
            WHERE Location_Id__c IN :locationIds
        ]) {
            locationToAccount.put(acc.Location_Id__c, acc);
        }

        if (locationToAccount.isEmpty()) return;

        // 4. Account → Contacts
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : locationToAccount.values()) {
            accountIds.add(acc.Id);
        }

        Map<Id, List<Contact>> accountToContacts = new Map<Id, List<Contact>>();

        for (Practice_Contact_Role__c role : [
            SELECT Practice__c, Contact__r.Email
            FROM Practice_Contact_Role__c
            WHERE Role__c = 'Treatment Finder Lead Recipient'
            AND Practice__c IN :accountIds
        ]) {
            if (String.isBlank(role.Contact__r.Email)) continue;

            if (!accountToContacts.containsKey(role.Practice__c)) {
                accountToContacts.put(role.Practice__c, new List<Contact>());
            }

            accountToContacts.get(role.Practice__c).add(role.Contact__r);
        }

        if (accountToContacts.isEmpty()) return;

        // 5. Build Emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Lead> leadsToUpdate = new List<Lead>();

        for (Lead l : leads) {

            if (!locationToAccount.containsKey(l.Location_Id__c)) continue;

            Account acc = locationToAccount.get(l.Location_Id__c);

            if (!accountToContacts.containsKey(acc.Id)) continue;

            List<String> toAddresses = new List<String>();
            for (Contact c : accountToContacts.get(acc.Id)) {
                toAddresses.add(c.Email);
            }

            if (toAddresses.isEmpty()) continue;

            // 🔥 Parse JSON Insights
            Map<String, Object> tfData = parseJson(l.TF_JSON__c);

            String timeline = (String) tfData.get('timeline');
            String insurance = (String) tfData.get('insurance');
            String concern = (String) tfData.get('concern');
            String treatment = (String) tfData.get('treatment');

            // 🔥 Rating
            String rating = getRating(timeline);

            // Subject
            String subject = 'New Treatment Finder Lead: ' + l.FirstName + ' ' + l.LastName;
            if (rating != null) {
                subject = '*' + rating + '* ' + subject;
            }

            // Body
            String body = '';

            body += 'A new Treatment Finder lead has been submitted.<br/><br/>';

            if (rating == 'HOT') {
                body += '<b>NEXT BEST ACTION:</b> Contact immediately.<br/><br/>';
            } else if (rating == 'WARM') {
                body += '<b>NEXT BEST ACTION:</b> Follow up soon.<br/><br/>';
            } else {
                body += '<b>NEXT BEST ACTION:</b> Follow up when possible.<br/><br/>';
            }

            body += '===================<br/>';
            body += 'Patient Information<br/>';
            body += '===================<br/>';
            body += 'Name: ' + l.FirstName + ' ' + l.LastName + '<br/>';
            body += 'Email: ' + (l.Email != null ? l.Email : 'N/A') + '<br/>';
            body += 'Phone: ' + (l.Phone != null ? l.Phone : 'N/A') + '<br/>';
            body += 'Practice: ' + acc.Name + '<br/><br/>';

            body += '===================<br/>';
            body += 'Lead Insights<br/>';
            body += '===================<br/>';
            if (timeline != null) body += 'Ready to Start: ' + timeline + '<br/>';
            if (insurance != null) body += 'Insurance: ' + insurance + '<br/>';
            if (treatment != null) body += 'Interested In: ' + treatment + '<br/>';
            if (concern != null) body += 'Key Concern: ' + concern + '<br/>';

            // 🔥 Full Transcript
            body += '<br/>' + buildFullTranscript(l.TF_JSON__c);

            // Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setToAddresses(toAddresses);

            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea[0].Id);
            }

            emails.add(mail);

            // Mark as sent
            l.Lead_Notification_Sent_Date__c = Date.today();
            leadsToUpdate.add(l);
        }

		//Debug data
		System.debug('Leads found: ' + leads.size());
		System.debug('Accounts found: ' + locationToAccount.size());
		System.debug('Contacts found: ' + accountToContacts.size());

        // Send Emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }

        // Update Leads
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }

    // 🔥 SAFE conversion helper (FIXED)
    private static String convertToString(Object answerObj) {

        if (answerObj instanceof List<Object>) {
            List<Object> rawList = (List<Object>) answerObj;
            List<String> strList = new List<String>();

            for (Object o : rawList) {
                strList.add(String.valueOf(o));
            }

            return String.join(strList, ', ');
        }

        return String.valueOf(answerObj);
    }

    // 🔥 Parse Key Insights
    private static Map<String, Object> parseJson(String jsonStr) {

        Map<String, Object> result = new Map<String, Object>();
        if (String.isBlank(jsonStr)) return result;

        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);

        if (data.containsKey('quiz_result')) {
            List<Object> quiz = (List<Object>) data.get('quiz_result');

            for (Object q : quiz) {
                Map<String, Object> qMap = (Map<String, Object>) q;

                String question = (String) qMap.get('question');
                Object answerObj = qMap.get('answer');

                String answer = convertToString(answerObj);

                if (question != null) {
                    String qLower = question.toLowerCase();

                    if (qLower.contains('ready to start')) result.put('timeline', answer);
                    if (qLower.contains('insurance')) result.put('insurance', answer);
                    if (qLower.contains('dentures')) result.put('concern', answer);
                }
            }
        }

        if (data.containsKey('treatment_options')) {
            List<Object> treatments = (List<Object>) data.get('treatment_options');
            if (!treatments.isEmpty()) {
                Map<String, Object> t = (Map<String, Object>) treatments[0];
                result.put('treatment', (String) t.get('treatment_name'));
            }
        }

        return result;
    }

    // 🔥 Full Transcript Builder
    private static String buildFullTranscript(String jsonStr) {

        if (String.isBlank(jsonStr)) return '';

        String html = '';

        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);

        if (data.containsKey('quiz_result')) {

            html += '===============================<br/>';
            html += 'FULL TREATMENT FINDER RESPONSES<br/>';
            html += '===============================<br/><br/>';

            List<Object> quiz = (List<Object>) data.get('quiz_result');

            for (Object q : quiz) {
                Map<String, Object> qMap = (Map<String, Object>) q;

                String question = (String) qMap.get('question');
                question = question != null ? question.replace('\n', ' ') : '';

                Object answerObj = qMap.get('answer');
                String answer = convertToString(answerObj);

                html += '<b>Q:</b> ' + question + '<br/>';
                html += '<b>A:</b> ' + answer + '<br/><br/>';
            }
        }

        if (data.containsKey('treatment_options')) {

            html += '===============================<br/>';
            html += 'TREATMENT OPTIONS PRESENTED<br/>';
            html += '===============================<br/><br/>';

            List<Object> treatments = (List<Object>) data.get('treatment_options');

            for (Object tObj : treatments) {
                Map<String, Object> t = (Map<String, Object>) tObj;

                String name = (String) t.get('treatment_name');

                String price = '';
                if (t.containsKey('pricing')) {
                    Map<String, Object> pricing = (Map<String, Object>) t.get('pricing');
                    if (pricing.containsKey('monthly_range')) {
                        Map<String, Object> monthly = (Map<String, Object>) pricing.get('monthly_range');
                        price = '$' + String.valueOf(monthly.get('min')) + '/month';
                    }
                }

                html += '• <b>' + name + '</b>';
                if (price != '') html += ' (' + price + ')';
                html += '<br/>';
            }

            html += '<br/>';
        }

        return html;
    }

    // 🔥 Rating Logic
    private static String getRating(String timeline) {

        if (timeline == null) return 'COLD';

        timeline = timeline.toLowerCase();

        if (timeline.contains('asap') || timeline.contains('immediately')) return 'HOT';
        if (timeline.contains('1-2 months') || timeline.contains('soon')) return 'WARM';

        return 'COLD';
    }
}