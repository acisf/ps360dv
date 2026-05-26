@isTest
public class UserDetailsTest {

    @isTest
    public static void testToGetUserDetails() {       
        List<List<Id>> userId = new List<List<Id>>();
        List<List<User>> users = new List<List<User>>();

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
            LocaleSidKey = 'en_US'            
       );
        insert user1;
        userId.add(new List<Id>{user1.id});
        users = UserDetails.getUserDetails(userId);
        System.assertEquals(users[0][0].Name,'Test1 User1');        

    }
}