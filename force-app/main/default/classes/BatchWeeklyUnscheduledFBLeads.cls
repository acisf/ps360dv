public class BatchWeeklyUnscheduledFBLeads 
    implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    public static Boolean isTestMode = false;
     public static Integer emailsSentCount = 0;

    private Map<String, List<FB_Lead__c>> leadsByPractice = new Map<String, List<FB_Lead__c>>();

    // START
    public Database.QueryLocator start(Database.BatchableContext bc) {

        if (Test.isRunningTest() || isTestMode) {
            return Database.getQueryLocator([
                SELECT Id,
                       FB_Contact__c,
                       FB_Contact__r.Name,
                       FB_Practice__c,
                       FB_Practice__r.Name,
                       FB_Practice__r.FB_Practice_Email__c,
                       FB_Practice__r.FB_Practice_CC_Email__c,
                       FB_Practice__r.FDA_Email__c,
                       FB_Practice__r.Location_Id_5_Digit__c,
                       FB_Phone__c,
                       FB_Email__c,
                       FB_What_Service__c,
                       FB_Using_Insurance__c,
                       FB_Insurance_Provider__c,
                       FB_How_Quickly__c,
                       Scheduled__c,
                       CreatedDate,
                       Practice_Id__c
                FROM FB_Lead__c
                WHERE Practice_Id__c != '0'
                  AND Scheduled__c = 0
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id,
                   FB_Contact__c,
                   FB_Contact__r.Name,
                   FB_Practice__c,
                   FB_Practice__r.Name,
                   FB_Practice__r.FB_Practice_Email__c,
                   FB_Practice__r.FB_Practice_CC_Email__c,
                   FB_Practice__r.FDA_Email__c,
                   FB_Practice__r.Location_Id_5_Digit__c,
                   FB_Phone__c,
                   FB_Email__c,
                   FB_What_Service__c,
                   FB_Using_Insurance__c,
                   FB_Insurance_Provider__c,
                   FB_How_Quickly__c,
                   Scheduled__c,
                   CreatedDate,
                   Practice_Id__c
            FROM FB_Lead__c
            WHERE Practice_Id__c != '0'
              AND Scheduled__c = 0
              AND CreatedDate = LAST_N_DAYS:6
        ]);
    }

    // EXECUTE
    public void execute(Database.BatchableContext bc, List<FB_Lead__c> scope) {

        for (FB_Lead__c lead : scope) {
            if (!leadsByPractice.containsKey(lead.Practice_Id__c)) {
                leadsByPractice.put(lead.Practice_Id__c, new List<FB_Lead__c>());
            }
            leadsByPractice.get(lead.Practice_Id__c).add(lead);
        }
    }

    // FINISH
    public void finish(Database.BatchableContext bc) {

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Org-Wide Email
        OrgWideEmailAddress[] owea = [
            SELECT Id FROM OrgWideEmailAddress 
            WHERE Address = 'patientsupport@affordablecare.com'
            LIMIT 1
        ];

        for (String practiceId : leadsByPractice.keySet()) {

            List<FB_Lead__c> leads = leadsByPractice.get(practiceId);
            if (leads.isEmpty()) continue;

            FB_Lead__c sample = leads[0];

            // -----------------------------
            // TO Addresses
            // -----------------------------
            List<String> toAddr = new List<String>();

            if (sample.FB_Practice__r.FB_Practice_Email__c != null) {
                toAddr = sample.FB_Practice__r.FB_Practice_Email__c.split(',');
            } else if (sample.FB_Practice__r.FDA_Email__c != null) {
                toAddr.add(sample.FB_Practice__r.FDA_Email__c);
            }

            if (toAddr == null || toAddr.isEmpty()) continue;

            // -----------------------------
            // CC Addresses
            // -----------------------------
            List<String> ccAddr = new List<String>();

            if (sample.FB_Practice__r.FB_Practice_CC_Email__c != null) {
                ccAddr = sample.FB_Practice__r.FB_Practice_CC_Email__c.replace(';', ',').split(',');
            }

            // -----------------------------
            // BCC Addresses (Always include Doug)
            // -----------------------------
            List<String> bccAddr = new List<String>();
            bccAddr.add('douglas.vann@affordablecare.com');

            // -----------------------------
            // Categorize Leads
            // -----------------------------
            List<FB_Lead__c> hot = new List<FB_Lead__c>();
            List<FB_Lead__c> warm = new List<FB_Lead__c>();
            List<FB_Lead__c> cold = new List<FB_Lead__c>();

            for (FB_Lead__c l : leads) {
                String urgency = l.FB_How_Quickly__c;

                if (urgency != null && urgency.contains('im_ready_now')) {
                    hot.add(l);
                } else if (urgency != null && urgency.contains('within_the_next_30_days')) {
                    warm.add(l);
                } else {
                    cold.add(l);
                }
            }

            // -----------------------------
            // Subject
            // -----------------------------
            String subject = 'Weekly Follow-Up Needed: ' + leads.size() +
                ' Unscheduled Leads - Location ' + sample.FB_Practice__r.Location_Id_5_Digit__c;

            // -----------------------------
            // Intro (Valerie)
            // -----------------------------
            String html = ''
            + '<p>Here’s your weekly recap of new patient opportunities from our Facebook Leads program. '
            + 'The leads on this list have not yet scheduled an appointment. We’ve organized them by urgency. '
            + 'Those with a longer timeframe may need more support and are still early in their decision process. '
            + 'Those with shorter timeframes may still have questions or hesitation, but are looking to move forward more quickly.</p>'
            + '<p>If you have any questions about this report or Facebook leads, please contact Marketing through the ACE Service portal '
            + 'or email <a href="mailto:acmarketing@affordablecare.com">acmarketing@affordablecare.com</a>.</p><br/>';

            html += '<h2>Weekly Unscheduled Facebook Leads</h2>';
            html += '<b>Practice:</b> ' + sample.FB_Practice__r.Name + '<br/>';
            html += '<b>Total Leads:</b> ' + leads.size() + '<br/><br/>';

            html += '<b>Ready to Schedule Now:</b> ' + hot.size() + '<br/>';
            html += '<b>Within 30 Days:</b> ' + warm.size() + '<br/>';
            html += '<b>Exploring:</b> ' + cold.size() + '<br/><br/>';

            html += buildTable('Ready Now (High Priority)', hot);
            html += buildTable('Within 30 Days', warm);
            html += buildTable('Exploring', cold);

            html += '<br/><b>Next Best Action:</b><br/>';
            html += 'Contact "Ready Now" leads within 24 hours via call or text.<br/>';

            // -----------------------------
            // Build Email
            // -----------------------------
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea[0].Id);
            }

            mail.setToAddresses(toAddr);

            if (!ccAddr.isEmpty()) {
                mail.setCcAddresses(ccAddr);
            }

            mail.setBccAddresses(bccAddr);

            mail.setSubject(subject);
            mail.setHtmlBody(html);
            mail.setPlainTextBody(html.stripHtmlTags());

            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
            emailsSentCount = emails.size();
        }
    }

    // TABLE BUILDER
    private static String buildTable(String title, List<FB_Lead__c> leads) {
        if (leads.isEmpty()) return '';

        String html = '<h3>' + title + '</h3>';
        html += '<table border="1" cellpadding="5" cellspacing="0">';
        html += '<tr><th>Name</th><th>Phone</th><th>Service</th><th>Insurance</th></tr>';

        for (FB_Lead__c l : leads) {
            html += '<tr>';
            html += '<td>' + (l.FB_Contact__r != null ? l.FB_Contact__r.Name : '') + '</td>';
            html += '<td>' + l.FB_Phone__c + '</td>';
            html += '<td>' + l.FB_What_Service__c + '</td>';
            html += '<td>' + l.FB_Using_Insurance__c + '</td>';
            html += '</tr>';
        }

        html += '</table><br/>';
        return html;
    }

    // SCHEDULER
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchWeeklyUnscheduledFBLeads(), 200);
    }
}