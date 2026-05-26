@isTest
public class CustomerCommunityControllerTest {
 
    
    @isTest static void testcontroller() {
        User u;
        u = CustomerCommunityController.getLoggedInUser();
        System.assert(u.id == UserInfo.getUserId());
    }
        
}