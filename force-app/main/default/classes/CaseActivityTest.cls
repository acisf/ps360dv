@isTest
public class CaseActivityTest {

    @isTest
    public static void testCaseActivityCreation(){
        
        Account a = new Account(Name= 'Test Account');
        insert a;        
        Contact con = new Contact(FirstName='Test', LastName='Contact', AccountId=a.id, email='test.contact@affordablecare.com');
        insert con;
        
        CaseActivity.CaseActivities c_act = new CaseActivity.CaseActivities();
        List<CaseActivity.CaseActivities> ca = new List<CaseActivity.CaseActivities>();
        Id aceservice = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ACE Service').getRecordTypeId();
        //Create case of ACE Service RT
        Case c1 = new Case();
        c1.AccountId = a.id;
        c1.ContactId = con.id;
        c1.Subject = 'Salesforce login issue';
        c1.Description = 'Salesforce login issue';
        c1.Team__c = 'IT';
        c1.Category__c = 'Enterprise Applications';
        c1.Subcategory__c = 'Salesforce';
        c1.Origin = 'Email';
        c1.RecordTypeId = aceservice;
        insert c1;        
        
        //Create feeditem related to the case
        FeedItem feed = new FeedItem();
        feed.parentId = c1.id;
        feed.Body = 'This is comment related to case';
        insert feed; 
        
        //Pass the parameters to the Invocable method
        c_act.caseId = c1.id;
        c_act.rec_id = feed.Id;
        c_act.type = 'FeedItem';
        ca.add(c_act);        
  
        //Create task related to case
        Task t = new Task();
        t.WhatId = c1.Id;
        t.Subject = 'Log a call';
        insert t;
        CaseActivity.createCaseActivity(ca); 
        
        //Pass the parameters to the Invocable method
        c_act.caseId = c1.id;
        c_act.rec_id = t.Id;
        c_act.type = 'Task';
        ca.add(c_act);
        CaseActivity.createCaseActivity(ca); 
   
        //Send email for the case
        EmailMessage em = new EmailMessage();
        em.parentId = c1.Id;
        em.Subject = 'Test email';
        em.Incoming = false;
        insert em;
        
        //Pass the parameters to the Invocable method
        c_act.caseId = c1.id;
        c_act.rec_id = em.Id;
        c_act.type = 'Email';
        ca.add(c_act);
        
        CaseActivity.createCaseActivity(ca);     
        List<Case_Activity__c> activities = [Select id from Case_Activity__c where case__c = :c1.id];
        System.assert(activities.size() > 0);        
    }
}