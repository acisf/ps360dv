@isTest
public with sharing class UserDetailsFromRoleTest {

    @isTest
    public static void testGetUserDetailsFromRole() {
        List<List<Id>> grpId = new List<List<Id>>();
        List<List<Id>> userId = new List<List<Id>>();
        UserRole r = new UserRole(DeveloperName = 'Purchasing1', Name = 'Purchasing1');
        insert r;

        User user1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Info Tech'].Id,
            FirstName = 'Test1',
            LastName = 'User1',
            Email = 'Test1User1@sample.com',
            Username = 'Test1User1@sample.com' + System.currentTimeMillis(),
            CompanyName = 'Test Company',
            Title = 'Developer',
            Alias = 'tu1',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = r.Id            
       );
        insert user1;

        Group publicGrp = new Group(type='Regular',name='Purchasing');
        insert publicGrp;

        Group publicGrpWithRole = [Select id from Group where type = 'Role' 
                                   and RelatedId = :r.id];

        GroupMember grpMember = new GroupMember(groupid = publicGrp.id,userorgroupid = publicGrpWithRole.id);
        insert grpMember;
        
        grpId.add(new List<Id>{publicGrp.id});       
        userId = UserDetailsFromRole.getUserDetailsFromRole(grpId);
        System.assertEquals(userId[0][0],user1.id);
    }
}