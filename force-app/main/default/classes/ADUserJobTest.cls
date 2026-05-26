@istest
public class ADUserJobTest {
    Account a;
    @isTest static void testAdUserJob() {
        
        //test user
        User u = new User(Username= 'juser@example.com',
                          FirstName='john',
                          lastname='user',
                          email='juser@example.com',
                          alias='juser',
                          phone='(804)555-1212',
                          department='Test',
                          TimeZoneSidKey = 'America/New_York',
                          LocaleSidKey = 'en_US',
                          EmailEncodingKey = 'ISO-8859-1',
                          ProfileId = '00e36000000OlsZAAS',
                          LANGUAGELOCALEKEY='en_US',
                          isActive = true);
        insert u;
        
        //test practice employee john doe
        Account a;
        Id saId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Schedule Assist').getRecordTypeId();
        a = new Account(name='Charlotte - North Carolina',Location_Id__c = '01002',recordtypeid=saId);
        insert a; 
        
        Id pid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Practice Employee').getRecordTypeId();
        Contact c1;
        c1 = new Contact(AccountId=a.id,LastName='Doe',FirstName='John',email='john@example.com',recordtypeid=pid);
        insert c1;
        
        //test corporate employee lester tester
        Account a2;
        Id aId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Appointment').getRecordTypeId();
        a2 = new Account(name='Affordable Care, LLC',Location_Id__c = '0',recordtypeid=aId);
        insert a2; 
        
        Id cid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Corporate Employee').getRecordTypeId();
        Contact c2;
        c2 = new Contact(AccountId=a2.id,LastName='T',FirstName='L',email='lester@example.com',recordtypeid=pid,
                        Work_Phone__c=null,Department=null,title=null,Active_Contact__c=false,
                        CreatedDate = DateTime.now()-1,LastModifiedDate = DateTime.now()-1);
        insert c2;
        
        //existing practice employee in A.D.
        Ad_user__c ad1;
        ad1 = new Ad_user__c(Active__c=true,First_Name__c='John',Last_Name__c='Doe',PracticeDescription__c='01002 Charlotte',Email__c='john@example.com');
        insert ad1;
        
        //new practice employee in A.D.
        Ad_user__c ad2;
        ad2 = new Ad_user__c(Active__c=true,First_Name__c='Jane',Last_Name__c='Smith',PracticeDescription__c='01002 Charlotte',Email__c='jane@example.com');
        insert ad2;
        
        //existing corporate employee in A.D.
        Ad_user__c ad3;
        ad3 = new Ad_user__c(Active__c=true,First_Name__c='Lester',Last_Name__c='Tester',PracticeDescription__c='Accountant',
                             Department__c='Accounting',Email__c='lester@example.com',Phone_Number__c='(804)555-1212',Job_Title__c='Test');
        insert ad3;
        
        //new corporate user in A.D.
        Ad_user__c ad4;
        ad4 = new Ad_user__c(Active__c=true,First_Name__c='Jack',Last_Name__c='D',PracticeDescription__c='Accountant',Email__c='jack@example.com');
        insert ad4;
        
        //exisiting SF user in A.D. has been deactivated in A.D.
        Ad_user__c ad5;
        ad5 = new Ad_user__c(Active__c=false,First_Name__c='Joe',Last_Name__c='Smith',Phone_Number__c='(800)555-1212', Department__c='Accounting',Job_Title__c='Accountant',Email__c='juser@example.com');
        insert ad5;
        
        Test.startTest();
        DateTime dt = DateTime.newInstance(Date.today(),Time.newInstance(0,0,0,0));
        adUserJob.runJob(dt);
        Test.stopTest();
        
        ad1 = [select id, contact__c from ad_user__c where email__c = 'john@example.com'];
        system.assert(ad1.contact__c != null);
        
        ad2 = [select id, contact__c from ad_user__c where email__c = 'jane@example.com'];
        system.assert(ad2.contact__c != null);
        
        ad3 = [select id, contact__c from ad_user__c where email__c = 'lester@example.com'];
        system.assert(ad3.contact__c != null);
        
        ad4 = [select id, contact__c from ad_user__c where email__c = 'jack@example.com'];
        system.assert(ad3.contact__c != null);
        
        u = [select id, firstname,lastname,email,isactive from user where email = 'juser@example.com'];
        system.assert(u.IsActive,false);
        
        
        
    }
}