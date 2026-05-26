@isTest(seeAllData = true)
public class BatchTaskUpdateTest {
    
    @isTest
    public static void testBatchTaskUpd(){     
        
        Account a = new Account(Name = 'Test Account');
        Insert a;
        List<Contact> cont = new List<Contact>();
        for(Integer i=0; i<10; i++){
            Contact c = new Contact(FirstName = 'ABC'+i, LastName = 'XYZ'+i, email = 'abc.xyz'+i+'@example.com', AccountId = a.Id);
            cont.add(c);
        }
        Insert cont;        
        List<FB_Lead__c> fb = new List<FB_Lead__c>();
        For(Contact c: cont){
            FB_Lead__c f = new FB_Lead__c(FB_Practice__c = a.id, FB_Contact__c = c.id);
            fb.add(f);
        }
        insert fb;              
        
        
        /*EmailStatus e = new EmailStatus();
        e.EmailTemplateName = 'FB1';*/
        
        EmailTemplate template = [Select Id from EmailTemplate where developerName = 'FB1'];
        List<Task> tsk = new List<Task>();
        FB_Lead__c f = [Select id, fb_Contact__c from FB_Lead__c where FB_Practice__c =: a.id limit 1];
        
       
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(f.FB_Contact__c);
            mail.setTemplateId(template.id);
            mail.setPlainTextBody('');
            mail.setWhatId(f.id);  
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setReplyTo('abc.xyz@example.com');
            mail.setSenderDisplayName('Test Email');
            mail.setSaveAsActivity(true);             
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
         for(FB_Lead__c f1 : fb){            
            Task tsk1 = new Task();
            tsk1.ActivityDate = System.today();
            tsk1.Subject = 'Test';
            tsk1.Status = 'Completed';
            tsk1.Priority = 'Normal';
            tsk1.WhoId = f1.FB_Contact__c;     
            tsk1.WhatId = f1.Id;
            tsk.add(tsk1);
        }        
        Insert tsk;
        
        Test.startTest();        
        Id jobid = Database.executeBatch(new batchTaskUpdate(),200);
        Test.stopTest();
                
        List<Task> t = [Select Id, Opened__c from Task Limit 1];
        System.assertEquals(t[0].Opened__c, false);
        
    }

}